{ vars, ... }:
{
  services.openssh = {
    enable = true;
    allowSFTP = true;
  };
  users.users.${vars.user}.openssh.authorizedKeys.keyFiles = [ ../keys/joel-mac.pub ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Preserve the host's resolver and use its existing OpenSSH authentication.
    extraSetFlags = [
      "--hostname=${vars.desktopHost}"
      "--accept-dns=false"
      "--ssh=false"
      "--operator=${vars.user}"
    ];
  };

  networking.networkmanager.wifi.powersave = false;
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };
}
