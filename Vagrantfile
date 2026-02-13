# -*- mode: ruby -*-
# vi: set ft=ruby :

# Define the number of master nodes
MASTER_COUNT = 1

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  
  config.vm.provision "shell", inline: <<-SHELL
    echo "192.168.56.11       openclaw-1" >> /etc/hosts
  SHELL

  1.upto(MASTER_COUNT) do |i|
    config.vm.define "openclaw#{i}" do |openclaw|
      openclaw.vm.hostname  = "openclaw-#{i}"
      openclaw.vm.provision "shell", path: "./scripts/assets.sh"
      openclaw.vm.network "private_network", ip: "192.168.56.#{i+10}"

      # Provider-specific configuration
      openclaw.vm.provider "virtualbox" do |vb|
        vb.gui = true
        vb.memory = "6144"
        vb.cpus = 2
        
        # Graphics and Hardware configuration
        vb.customize ["modifyvm", :id, "--vram", "256"]
        vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
        vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
        vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
        vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
        vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
        vb.customize ["modifyvm", :id, "--audio", "coreaudio"]
      end

      # Reboot after provisioning to start GUI
      openclaw.vm.provision "shell", inline: "shutdown -r now", run: "once"
    end
  end
end