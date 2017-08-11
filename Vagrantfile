Vagrant.configure("2") do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/xenial64"
  config.vm.provider 'virtualbox'
  config.vm.network "forwarded_port", guest: 80, host: 80,
    auto_correct: true
  config.vm.network "forwarded_port", guest: 3306, host: 3306,
    auto_correct: true
  config.vm.provision :shell, path: "bootstrap.sh"
end
