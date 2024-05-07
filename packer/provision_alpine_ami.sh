#!/bin/sh

set -ex

doas apk upgrade --no-cache
doas apk --no-cache add wireguard-tools-wg wireguard-tools-wg-quick nftables aws-cli

echo 'net.ipv4.ip_forward=1' | doas tee /etc/sysctl.d/local.conf

doas mkdir -p /etc/wireguard/

cat <<EOF | doas tee /etc/nftables.d/wireguard.nft
# https://xdeb.org/post/2019/09/26/setting-up-a-server-firewall-with-nftables-that-support-wireguard-vpn/ - IPv4, relevant bits
# Throw away the default Firewall rules
flush ruleset

# Set some variables that we can reuse
define vpn = wg0
# These will be replaced during cloud-init with the appropriate values
define vpn_port = 51820
define vpn_net = 10.0.1.0/24
define wan = eth0

table inet filter {
  
  # https://wiki.nftables.org/wiki-nftables/index.php/Sets
  set tcp_accepted { type inet_service; flags interval; elements = { 22 } }

  set udp_accepted { type inet_service; flags interval; elements = { \$vpn_port } }

  chain reusable_checks {
    # Drop invalid packets
    ct state invalid drop
    
    # Allow connections that are in an established state
    ct state established,related accept
  }

  chain input {
    type filter hook input priority 0; policy drop;

    # Include reusable_checks before continuing
    jump reusable_checks

    # Limit ping requests to 1 per second, with a burst upto 5
    ip protocol icmp icmp type echo-request limit rate over 1/second burst 5 packets drop

    # Allow connections on the local/loopback interface
    iif lo accept

    # Allow specific ping requests
    ip protocol icmp icmp type { destination-unreachable, echo-reply, echo-request, source-quench, time-exceeded } accept

    # Allow needed tcp and udp ports.
    iifname \$wan tcp dport @tcp_accepted ct state new accept
    iifname \$wan udp dport @udp_accepted ct state new accept

    # Allow WireGuard clients to access services.
    iifname \$vpn tcp dport @tcp_accepted ct state new accept
    iifname \$vpn udp dport @udp_accepted ct state new accept

    # Allow WireGuard clients to connect with each other
    iifname \$vpn oifname \$vpn ct state new accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop; 

    # Include reusable_checks before continuing
    jump reusable_checks

    # Allow WireGuard traffic to access the internet via wan.
    iifname \$vpn oifname \$wan ct state new accept

    # Allow WireGuard clients to connect with each other
    iifname \$vpn oifname \$vpn ct state new accept
  }

  chain output {
    type filter hook output priority 0; policy drop; 

    # Include reusable_checks before continuing
    jump reusable_checks

    # Allow new traffic to go out from this instance
    ct state new accept
  }
}

# VPN specific packet mangling rules
table ip nat {
  chain PREROUTING {
    type nat hook prerouting priority -100;
  }

  chain POSTROUTING {
    type nat hook postrouting priority 100;

    # Change the source address for any packet coming through the WireGuard interface 
    # and destined for the wider internet from the WireGuard client's internal IP
    # that of this instance before sending the traffic out
    ip saddr \$vpn_net oifname \$wan masquerade
  }
}
EOF

#cat <<EOF | doas tee -a /etc/network/interfaces
#auto wg0
#iface wg0 inet static
#  address 10.0.0.1
#  netmask 255.255.255.0
#  pre-up ip link add dev wg0 type wireguard
#  pre-up wg setconf wg0 /etc/wireguard/wg0.conf
#  post-down ip link delete dev wg0
#EOF

doas rc-update add nftables

echo 'alpine:alpine34' | doas chpasswd
