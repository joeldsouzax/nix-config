#
#  Network Discoverability
#

{
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      settings.publish = {
        disable-publishing = false;
        publish-addresses = true;
        disable-user-service-publishing = false;
      };
    };
  };
}
