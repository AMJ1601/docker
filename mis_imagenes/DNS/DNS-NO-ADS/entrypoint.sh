#!/bin/bash

# Actualizamos
curl -ssL "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" > /etc/dnsmasq.d/blacklist
tail /etc/dnsmasq.d/blacklist -n +40 > /etc/dnsmasq.d/blacklist.txt

# DNS en primer plano
exec dnsmasq --no-daemon --log-queries