# Vagrant version 2
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box       = 'precise32'
  config.vm.box_url   = 'http://files.vagrantup.com/precise32.box'

  config.vm.network "private_network", ip: "192.168.0.99"
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.synced_folder ".", "/vagrant", type: "nfs"
  # config.vm.share_folder "ninenine-delta", "/home/vagrant/ninenine-delta", ".", :nfs => true

  config.vm.provision :puppet,
    manifests_path: 'puppet/manifests',
    module_path: 'puppet/modules'
end

## ===== UPDATE RVM =====
# curl -L https://get.rvm.io | bash -s stable --ruby
# rvm install 2.0.0
# rvm use 2.0.0
# gem install rails --no-rdoc --no-ri

# sudo apt-get install libpq-dev
# sudo -u postgres createuser vagrant
# sudo -i -u postgres
# psql
# ALTER ROLE vagrant CREATEDB;
# UPDATE pg_database SET datistemplate=false WHERE datname='template1';
# DROP DATABASE Template1;
# CREATE DATABASE template1 WITH owner=postgres encoding='UTF-8' lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0;
# UPDATE pg_database SET datistemplate=true WHERE datname='template1';

