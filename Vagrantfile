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
