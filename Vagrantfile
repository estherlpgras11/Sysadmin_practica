# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
 	config.vm.define "elk" do |elk|
    	elk.vm.box = 'ubuntu/xenial64'
    	elk.vm.box_check_update = false
    	elk.vm.synced_folder ".", "/vagrant"
    	elk.vm.network "private_network", ip: "10.0.15.31"
    	elk.vm.network "forwarded_port", guest: 5601, host: 5600 #kivana 
      elk.vm.network "forwarded_port", guest: 9200, host: 9201 #elastic
      elk.vm.network "forwarded_port", guest: 5044, host: 5045 #logstash 
      elk.vm.provider "virtualbox" do |vb|
      		vb.memory = "3500"
      		vb.cpus = 2
    	end
   	 	elk.vm.provision "shell", path: "ELK_configure.sh" 
  	end

  	config.vm.define "ubuntu" do |ubuntu|
    	ubuntu.vm.box = "ubuntu/xenial64"
    	ubuntu.vm.box_check_update = false
    	ubuntu.vm.synced_folder ".", "/vagrant"
    	ubuntu.vm.network "private_network", ip: "10.0.15.30"
    	ubuntu.vm.network "forwarded_port", guest: 80, host: 8000 #wordpress
    	ubuntu.vm.provider "virtualbox" do |vb|
      		vb.memory = "824"
    	end
    	ubuntu.vm.provision "shell", path: "bootstrap.sh"
  	end
end