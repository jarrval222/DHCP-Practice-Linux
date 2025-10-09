# Configuración de Servidor DHCP en Linux (Ubuntu Xenial64) con Vagrant

## 1. Objetivo de la práctica

Configurar un **servidor DHCP en Linux** con dos interfaces de red y varios clientes que obtendrán su configuración de red automáticamente.  
Uno de los clientes recibirá una **IP fija basada en su MAC address**.

---

## 2. Configuración del Servidor Linux

### 2.1 Red en Vagrant

En el `Vagrantfile` definimos dos interfaces de red:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.define "dhcp-server" do |dhcp|
    dhcp.vm.hostname = "dhcp-server"
    dhcp.vm.network "private_network", ip: "192.168.56.10"
    dhcp.vm.network "private_network", ip: "192.168.57.10", virtualbox_intnet: "dhcpnet"
    dhcp.vm.provision "shell", path: "scripts/dhcp_provision.sh"
  end
  config.vm.define "c1" do |client|
    client.vm.hostname = "c1"
    client.vm.network "private_network", type:"dhcp", virtualbox_intnet: "dhcpnet"
  end
  config.vm.define "c2" do |client|
    client.vm.hostname = "c2"
    client.vm.network "private_network", type:"dhcp", virtualbox_intnet: "dhcpnet"
  end
end
```

En la máquina servidor:

```bash
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

```

## 3. Configuración del Servicio DHCP

En este apartado configuramos el servicio **ISC DHCP Server** para que atienda a los clientes de la red interna `192.168.57.0/24`.

### 3.1 Address range

```conf

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
log-facility local7;

subnet 192.168.57.0 netmask 255.255.255.0 {
 range 192.168.57.25 192.168.57.50;
 option routers 192.168.57.10;
 option domain-name-servers 8.8.8.8, 4.4.4.4;
 option domain-name "micasa.es";
 default-lease-time 86400;
 max-lease-time 691200;
}

```

### 3.2 Verification

```txt

● isc-dhcp-server.service - ISC DHCP IPv4 server
   Loaded: loaded (/lib/systemd/system/isc-dhcp-server.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2025-10-03 08:27:36 UTC; 13min ago
     Docs: man:dhcpd(8)
 Main PID: 3190 (dhcpd)
    Tasks: 1
   Memory: 9.0M
      CPU: 21ms
   CGroup: /system.slice/isc-dhcp-server.service
           └─3190 dhcpd -user dhcpd -group dhcpd -f -4 -pf /run/dhcp-server/dhcpd.pid -cf /etc/dhcp/dhcpd.conf

```

```txt

State       Recv-Q Send-Q                 Local Address:Port                                Peer Address:Port
UNCONN      0      0                                  *:40831                                          *:*
UNCONN      0      0
*:67                                             *:*
UNCONN      0      0                                  *:68                                             *:*
UNCONN      0      0
*:::34116                                         *:::*

```

### 4.2 Review logs

```txt

ifup[778]: DHCPDISCOVER on enp0s3 to 255.255.255.255 port 67 interval 3 (xid=0x7c520b36)
dhclient[866]: DHCPDISCOVER on enp0s3 to 255.255.255.255 port 67 interval 3 (xid=0x7c520b36)
dhclient[866]: DHCPREQUEST of 10.0.2.15 on enp0s3 to 255.255.255.255 port 67 (xid=0x360b527c)
ifup[778]: DHCPREQUEST of 10.0.2.15 on enp0s3 to 255.255.255.255 port 67 (xid=0x360b527c)
ifup[778]: DHCPOFFER of 10.0.2.15 from 10.0.2.2
ifup[778]: DHCPACK of 10.0.2.15 from 10.0.2.2
dhclient[866]: DHCPOFFER of 10.0.2.15 from 10.0.2.2
dhclient[866]: DHCPACK of 10.0.2.15 from 10.0.2.2
dhcpd[3190]: DHCPDISCOVER from 08:00:27:cf:f4:fd via enp0s9
dhcpd[3190]: DHCPOFFER on 192.168.57.25 to 08:00:27:cf:f4:fd (c1) via enp0s9
dhcpd[3190]: DHCPREQUEST for 192.168.57.25 (192.168.57.10) from 08:00:27:cf:f4:fd (c1) via enp0s9
dhcpd[3190]: DHCPACK on 192.168.57.25 to 08:00:27:cf:f4:fd (c1) via enp0s9

```

### 4.3 View leases

```conf

# The format of this file is documented in the dhcpd.leases(5) manual page.
# This lease file was written by isc-dhcp-4.3.3

server-duid "\000\001\000\0010rEx\010\000'\261\322h";

lease 192.168.57.25 {
  starts 5 2025/10/03 08:30:27;
  ends 6 2025/10/04 08:30:27;
  cltt 5 2025/10/03 08:30:27;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 08:00:27:cf:f4:fd;
  client-hostname "c1";
}

```

```conf

lease 192.168.57.26 {
  starts 5 2025/10/03 08:34:11;
  ends 6 2025/10/04 08:34:11;
  cltt 5 2025/10/03 08:34:11;
  binding state active;
  next binding state free;
  rewind binding state free;
  hardware ethernet 08:00:27:2c:95:be;
  client-hostname "c2";
}

```
