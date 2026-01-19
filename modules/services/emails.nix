{ config, pkgs, ... }: {

  environment.systemPackages = with pkgs; [ isync msmtp mu ];
}
