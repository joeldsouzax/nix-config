{ lib, pkgs, ... }: {

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
      "1password-gui"
      "1password-cli"
    ];

  programs._1password = { enable = true; };

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "joel@trive.ai" ];
  };

  environment.extraInit = ''
    # Use 1Password as the SSH_AUTH_SOCK
    if [ -f $HOME/.1password/agent.sock ]; then
        export SSH_AUTH_SOCK=$HOME/.1password/agent.sock
    fi
  '';
}
