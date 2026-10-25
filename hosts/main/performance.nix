{ config, lib, ... }:
{
  # Six CPU cores and 16 GiB RAM: keep room for SSH and other host services.
  nix.settings = {
    max-jobs = 1;
    cores = 4;
  };
  environment.variables.CARGO_BUILD_JOBS = toString config.nix.settings.cores;

  # Both /var and /nix/store are on SSD. Large builds must not consume a tmpfs.
  boot.tmp.useTmpfs = false;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
