{
  config,
  pkgs,
  vars,
  ...
}:
let
  gmailOauth2Tool = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/google/gmail-oauth2-tools/master/python/oauth2.py";
    sha256 = "sha256-AHikPTqwpyEU1wnTaZVvq8CsOe/sWuq10/fSbEzlsnA=";
  };
  fetchGmailToken = pkgs.writeShellScript "fetch-gmail-token" ''
    ${pkgs.python3}/bin/python3 ${gmailOauth2Tool} \
      --user=$(cat ${config.sops.secrets.gmail_email.path}) \
      --client_id=$(cat ${config.sops.secrets.gmail_client_id.path}) \
      --client_secret=$(cat ${config.sops.secrets.gmail_client_secret.path}) \
      --refresh_token=$(cat ${config.sops.secrets.gmail_refresh_token.path}) \
      --quiet
  '';
  sasl-xoauth2-custom = pkgs.stdenv.mkDerivation rec {
    pname = "sasl-xoauth2";
    version = "0.24";
    src = pkgs.fetchFromGitHub {
      owner = "tarickb";
      repo = "sasl-xoauth2";
      rev = "release-${version}";
      sha256 = "sha256-XHeUAJ8a1DDhj0i7y/agYsbTdUgVNehCas78VsOBQ9Q=";
    };
    nativeBuildInputs = with pkgs; [
      cmake
      pandoc
      pkg-config
      curl
      jsoncpp
    ];
    buildInputs = [ pkgs.cyrus_sasl ];
    cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  };
in
with pkgs;
{
  sops.secrets.gmail_email = {
    owner = "joel";
  };
  sops.secrets.gmail_client_id = {
    owner = "joel";
  };
  sops.secrets.gmail_client_secret = {
    owner = "joel";
  };
  sops.secrets.gmail_refresh_token = {
    owner = "joel";
  };
  environment.systemPackages = [
    isync
    msmtp
    mu
  ];
  home-manager.users.${vars.user} =
    { pkgs, config, ... }:
    {
      home.packages = [ sasl-xoauth2-custom ];
      home.sessionVariables = {
        SASL_PATH = "${pkgs.cyrus_sasl}/lib/sasl2:${sasl-xoauth2-custom}/lib/sasl2";
      };
      home.shellAliases = {
        mbsync = "mbsync -c ~/.config/isyncrc";
      };
      accounts.email.accounts."trive" = {
        primary = true;
        address = "joel@trive.ai";
        userName = "joel@trive.ai";
        realName = "Joel";
        flavor = "gmail.com";
        imap = {
          authentication = "xoauth2";
        };

        smtp = {
          authentication = "xoauth2";
          tls.useStartTls = true;
        };

        passwordCommand = "${fetchGmailToken}";
        mbsync.enable = true;
        msmtp.enable = true;
        mu.enable = true;
        mbsync = {
          create = "maildir";
          expunge = "both";
          extraConfig.account = {
            AuthMechs = "XOAUTH2";
            PipelineDepth = 50;
            Timeout = 120;
          };
          groups.trive.channels = {
            inbox = {
              farPattern = "INBOX";
              nearPattern = "INBOX";
            };
            all = {
              farPattern = "[Gmail]/All Mail";
              nearPattern = "Archive";
            };
            sent = {
              farPattern = "[Gmail]/Sent Mail";
              nearPattern = "Sent";
            };
            trash = {
              farPattern = "[Gmail]/Trash";
              nearPattern = "Trash";
            };
          };
        };
      };

      programs.mbsync.enable = true;
      programs.msmtp.enable = true;
    };

}
