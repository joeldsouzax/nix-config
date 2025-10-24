# Qemu/KVM With Virt-Manager
#

{ config, pkgs, vars, ... }:

{
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_nsrs=1
  ''; # For OSX-KVM

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
        verbatimConfig = ''
          nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
        '';
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      virt-manager # VM Interface
      virt-viewer # Remote VM
      qemu # Virtualizer
      OVMF # UEFI Firmware
      gvfs # Shared Directory
      swtpm # TPM
      virglrenderer # Virtual OpenGL
    ];
  };

  services = { gvfs.enable = true; };
}

