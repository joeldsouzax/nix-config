# NixOS Performance Tuning
# Optimized for 16GB RAM desktop with swap partition
#
# Key optimizations:
#   - zram compressed RAM swap (effectively adds ~8GB swap)
#   - Aggressive dirty page writeback (prevents I/O stalls)
#   - earlyoom (prevents system freeze under OOM pressure)
#   - Tuned vm.swappiness for desktop responsiveness

{ lib, pkgs, ... }:

{
  # ── zram: Compressed RAM-backed swap ──────────────────────────────────
  # Creates a compressed block device in RAM. With 16GB, zram at 50%
  # gives ~8GB compressed swap before hitting real disk swap.
  # Compression ratio is typically 2-3x, so effectively 16-24GB virtual.
  zramSwap = {
    enable = true;
    algorithm = "zstd";        # Best ratio + speed balance
    memoryPercent = 50;        # Use up to 8GB RAM for compressed swap
    priority = 100;            # Higher priority than disk swap (usually 0)
  };

  # ── Kernel parameters for 16GB desktop ────────────────────────────────
  boot.kernel.sysctl = {
    # ── Virtual Memory ──
    # Lower swappiness = prefer keeping apps in RAM (good for desktop)
    # With zram, we can be slightly more aggressive than default 60
    "vm.swappiness" = 10;

    # Write dirty pages to disk sooner (prevents I/O stalls)
    "vm.dirty_ratio" = 10;                # % of RAM before synchronous writeback
    "vm.dirty_background_ratio" = 5;      # % of RAM before async writeback starts
    "vm.dirty_expire_centisecs" = 1500;   # 15s before dirty data is old enough to write
    "vm.dirty_writeback_centisecs" = 500; # Check for dirty pages every 5s

    # Better memory compaction (reduces fragmentation)
    "vm.compaction_proactiveness" = 20;

    # VFS cache pressure — lower = keep directory/inode caches longer
    # Good for code navigation and build systems
    "vm.vfs_cache_pressure" = 50;

    # ── Network (good defaults for dev work) ──
    "net.core.rmem_max" = 16777216;          # 16MB receive buffer
    "net.core.wmem_max" = 16777216;          # 16MB send buffer
    "net.ipv4.tcp_fastopen" = 3;             # Enable TCP Fast Open (client+server)
    "net.ipv4.tcp_congestion_control" = "bbr"; # BBR congestion control

    # ── File system ──
    "fs.inotify.max_user_watches" = 524288;  # More inotify watchers (needed for large codebases)
    "fs.inotify.max_user_instances" = 1024;
    "fs.file-max" = 2097152;                 # Max open files system-wide
  };

  # Enable BBR congestion control module
  boot.kernelModules = [ "tcp_bbr" ];

  # ── earlyoom: Prevent system freeze under memory pressure ─────────────
  # Without earlyoom, Linux OOM killer activates too late and the system
  # becomes unresponsive. earlyoom kills the biggest memory hog early.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;      # Act when <5% RAM free
    freeSwapThreshold = 10;    # Act when <10% swap free
    enableNotifications = true; # Desktop notification on kill
  };

  # ── I/O scheduler ────────────────────────────────────────────────────
  # For NVMe/SSD: mq-deadline or none. For HDD: bfq
  services.udev.extraRules = ''
    # NVMe drives — no scheduler (fastest for NVMe)
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    # SATA SSD — mq-deadline
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    # HDD — BFQ (fair queuing for rotational)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  # ── systemd-oomd as backup ────────────────────────────────────────────
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };

  # NOTE: boot.tmp is already configured in hosts/configuration.nix (5GB tmpfs)
}
