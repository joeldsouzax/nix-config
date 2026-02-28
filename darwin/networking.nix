# Networking Configuration for macOS
# Replicates the NixOS dnsmasq + nginx setup for trive.ai development
#
# NixOS approach:
#   services.dnsmasq → resolves *.trive.ai to 127.0.0.1
#   services.nginx → TLS passthrough to VM at 192.168.123.100
#
# Darwin approach:
#   /etc/resolver/trive.ai → macOS native per-domain resolver
#   dnsmasq (Homebrew) → local DNS for *.trive.ai
#   nginx (Homebrew) → TLS passthrough to VM

{ lib, vars, ... }:

{
  # ── macOS Native DNS Resolver ───────────────────────────────────────────
  # macOS checks /etc/resolver/<domain> for per-domain nameserver overrides.
  # This tells macOS to ask local dnsmasq for all *.trive.ai lookups.
  environment.etc."resolver/trive.ai" = {
    text = ''
      nameserver 127.0.0.1
      port 5353
    '';
  };

  # ── Service Configuration (applied on darwin-rebuild switch) ────────────
  # These activation scripts configure Homebrew services to match the NixOS setup.
  system.activationScripts.postActivation.text = ''
    echo "Configuring trive.ai development networking..."

    # Configure dnsmasq (mirrors NixOS services.dnsmasq)
    DNSMASQ_CONF="/opt/homebrew/etc/dnsmasq.conf"
    if [ -d /opt/homebrew/etc ]; then
      cat > "$DNSMASQ_CONF" << 'DNSEOF'
# Trive development DNS — managed by nix-darwin
# Mirrors NixOS services.dnsmasq configuration
port=5353
server=1.1.1.1
server=8.8.8.8
domain-needed
bogus-priv
no-resolv
address=/trive.ai/127.0.0.1
address=/trive.ai/::1
address=/vm.trive.ai/192.168.123.100
DNSEOF
      echo "  dnsmasq config written to $DNSMASQ_CONF"
    fi

    # Configure nginx TLS passthrough (mirrors NixOS services.nginx.streamConfig)
    NGINX_CONF="/opt/homebrew/etc/nginx/nginx.conf"
    if [ -d /opt/homebrew/etc/nginx ]; then
      cat > "$NGINX_CONF" << 'NGXEOF'
# Trive TLS passthrough proxy — managed by nix-darwin
# Mirrors NixOS services.nginx.streamConfig
worker_processes 1;
events {
    worker_connections 1024;
}

stream {
    upstream trive_backend {
        server 192.168.123.100:443 max_fails=1 fail_timeout=5s;
    }

    server {
        listen 127.0.0.1:443;
        listen [::1]:443;
        proxy_pass trive_backend;
        ssl_preread on;
    }

    server {
        listen 127.0.0.1:80;
        proxy_pass trive_backend;
    }
}
NGXEOF
      echo "  nginx config written to $NGINX_CONF"
    fi

    echo ""
    echo "After first setup, start services with:"
    echo "  sudo brew services start dnsmasq"
    echo "  sudo brew services start nginx"
    echo ""
    echo "Verify DNS: dig @127.0.0.1 -p 5353 api.trive.ai"
  '';
}
