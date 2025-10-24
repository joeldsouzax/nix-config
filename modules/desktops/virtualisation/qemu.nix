# Qemu/KVM With Virt-Manager
#

{ config, pkgs, vars, ... }:

{
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_nsrs=1
  '';

  boot.kernelParams = [
    "systemd.unified_cgroup_hierarchy=1"
    "systemd.legacy_systemd_cgroup_controller=0"
  ];

  users.groups = {
    libvirtd.members = [ "root" "${vars.user}" ];
    kvm.members = [ "root" "${vars.user}" ];
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    spiceUSBRedirection.enable = true;
  };

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    OVMF
    swtpm
    virglrenderer
  ];
}

