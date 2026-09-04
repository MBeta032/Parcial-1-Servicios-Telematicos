# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  # ---------- VM1 : DNS MAESTRO ----------
  config.vm.define :maestro do |maestro|
    maestro.vm.box      = "bento/ubuntu-22.04"
    maestro.vm.network  :private_network, ip: "192.168.50.3"
    maestro.vm.hostname = "maestro"
    maestro.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"   # BIND9 + Apache con Brotli en la Parte 2
      vb.cpus   = 1
    end
  end

  # ---------- VM2 : DNS ESCLAVO ----------
  config.vm.define :esclavo do |esclavo|
    esclavo.vm.box      = "bento/ubuntu-22.04"
    esclavo.vm.network  :private_network, ip: "192.168.50.2"
    esclavo.vm.hostname = "esclavo"
    esclavo.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"   # antes 512 MB, causaba kernel panic
      vb.cpus   = 1
    end
  end

end