#!/usr/bin/bash
set -e

# create a tun device if not exist
# allow passing device to ensure compatibility with Podman
if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# start dbus
mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
    rm /run/dbus/pid
fi
dbus-daemon --config-file=/usr/share/dbus-1/system.conf

# Start warp-svc daemon in background
warp-svc --accept-tos &
sleep 2


# Register and connect to WARP
warp-cli --accept-tos registration new || true
sleep 1


warp-cli --accept-tos mode warp
warp-cli --accept-tos connect

# wait another seconds for the daemon to reconfigure
sleep 5

# enable NAT
echo "[NAT] Enabling NAT..."
nft add table ip nat
nft add chain ip nat WARP_NAT { type nat hook postrouting priority 100 \; }
nft add rule ip nat WARP_NAT oifname "CloudflareWARP" masquerade
nft add table ip mangle
nft add chain ip mangle forward { type filter hook forward priority mangle \; }
nft add rule ip mangle forward tcp flags syn tcp option maxseg size set rt mtu

nft add table ip6 nat
nft add chain ip6 nat WARP_NAT { type nat hook postrouting priority 100 \; }
nft add rule ip6 nat WARP_NAT oifname "CloudflareWARP" masquerade
nft add table ip6 mangle
nft add chain ip6 mangle forward { type filter hook forward priority mangle \; }
nft add rule ip6 mangle forward tcp flags syn tcp option maxseg size set rt mtu


# start the proxy
gost $GOST_ARGS


