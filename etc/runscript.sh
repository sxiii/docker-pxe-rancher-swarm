#!/bin/sh
cd /etc
python3 -m http.server 8888 &
dnsmasq --no-daemon --dhcp-range=10.42.0.1,10.42.0.254,255.255.255.0
