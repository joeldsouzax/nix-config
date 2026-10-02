# Defensive network and Wi-Fi auditing tools for macOS.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Discover and identify devices and exposed services on the local network.
    arp-scan
    macmon
    nmap

    # Capture and inspect traffic. Packet capture generally requires sudo.
    wireshark-cli
    termshark
    zeek
    ngrep
    tcpflow
    dnstop

    # Inspect local bandwidth and connections.
    bandwhich
    iftop
    sniffnet

    # Audit Wi-Fi and diagnose routing, DNS, latency, and throughput.
    aircrack-ng
    bind # dig, host, and nslookup
    mtr
    trippy
    iperf3

    # Inspect public ownership and router SNMP data (when enabled by the owner).
    whois
    net-snmp
  ];
}
