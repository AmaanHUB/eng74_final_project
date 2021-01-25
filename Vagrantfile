Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  # add port forwarding maybe
  config.vm.network "private_network", ip: "192.168.33.10"
#   config.vm.synced_folder "./", "/home/vagrant/it_jobswatch_devops_project/"

  config.vm.provision "ansible" do |ansible|
    ansible.verbose = "v"
    ansible.playbook = "./provisioning/main_standard.yaml"
  end
end

