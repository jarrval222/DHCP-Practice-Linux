#!/bin/bash

#Set logging mode
set -eux

#Update and install DHCP server
apt-get update && apt-get install -y isc-dhcp-server

#Restart DHCP service
systemctl restart isc-dhcp-server

#Backup original configuration file and replace it with the custom one
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
mv /vagrant/conf/dhcpd.conf /etc/dhcp/dhcpd.conf