# Sample nixosTest integration test.
#
# Runs a full NixOS guest VM, starts nginx, and asserts an HTTP response.
# This is the template — copy it for real integration tests.
#
# Run (offloads to a Linux builder — see darwin/linux-builder.nix):
#   nix build .#checks.x86_64-linux.integration -L    # → NixOS desktop (KVM, fast)
#   nix build .#checks.aarch64-linux.integration -L   # → local builder VM (fallback)
#   nix flake check                                    # builds every check
{ lib, ... }:
{
  name = "integration-nginx";

  nodes.machine = { pkgs, ... }: {
    services.nginx = {
      enable = true;
      virtualHosts."localhost".locations."/".return = "200 'hello from nixosTest'";
    };
    networking.firewall.allowedTCPPorts = [ 80 ];
    environment.systemPackages = [ pkgs.curl ];
  };

  # Python test driver — see the NixOS test-driver docs for the full API.
  testScript = ''
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(80)
    machine.succeed("curl -sSf http://localhost | grep 'hello from nixosTest'")
  '';
}
