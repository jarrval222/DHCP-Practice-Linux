#!/bin/bash

#Set logging mode
set -eux

#Update and install DHCP server
apt-get update && apt-get install -y isc-dhcp-server

#Restart DHCP service
systemctl restart isc-dhcp-server

#Get the interface name associated with the internal network
iface=$(ip a s | grep 192.168.57.10 -2 | head -1 | tr ': ' '\n' | grep enp)

#Configure DHCP server to listen on the internal network interface
sed -i "s/^INTERFACES=.*/INTERFACES=\"$iface\"/" /etc/default/isc-dhcp-server

#Backup original configuration file and replace it with the custom one
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
cp /vagrant/conf/dhcpd.conf /etc/dhcp/dhcpd.conf

#Restart DHCP service to apply new configuration
systemctl restart isc-dhcp-server