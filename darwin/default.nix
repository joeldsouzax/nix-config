{ pkgs, lib, inputs }: {
    environment = with pkgs; [];
    system.stateVersino = 6;
    nixpkgs.hostPlatform = "aarch64-darwin";
};
