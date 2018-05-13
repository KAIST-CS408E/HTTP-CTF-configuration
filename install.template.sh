# Download vagrant box from file hosting site since vagrant cloud is extremely SLOW
# wget <FILE_HOSTING_URL> -O package.box
# vagrant box remove hobin/create-ctf-competition-template -f
# vagrant box add hobin/create-ctf-competition-template ./package.box

# Create Vagrantfile
tee Vagrantfile << END
Vagrant.configure(2) do |config|
  config.vm.box = "hobin/create-ctf-competition-template"

  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 1
    v.customize ["modifyvm", :id, "--ioapic", "on"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provision "file", source: "./vagrant-install.sh", destination: "~/vagrant-install.sh"
  config.vm.provision "file", source: "./services", destination: "~/services"

  config.vm.provision "shell" do |s|
    s.inline = "sh vagrant-install.sh"
  end

  config.vm.network "forwarded_port", guest: 3306, host: 13306 # Mysql
  config.vm.network "forwarded_port", guest: 5001, host: 15001 # Gitlab
  config.vm.network "forwarded_port", guest: 8000, host: 18000 # CTF Dashboard
end
END

# Create vagrant-install.sh which will be executed inside the vagrant box
tee vagrant-install.sh << END
export VAGRANT_HOME=/home/vagrant

git clone https://github.com/KAIST-CS408E/HTTP-CTF.git

sudo mv \$VAGRANT_HOME/services \$VAGRANT_HOME/HTTP-CTF/services
pip install -r \$VAGRANT_HOME/HTTP-CTF/dashboard/requirements.txt

tee \$VAGRANT_HOME/HTTP-CTF/container-creator/ctf.json << END2
{* ctf.json *}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{* firebaseConfig.json *}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/teamConfig.json << END2
{* teamConfig.json *}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/static/js/firebase.init.js << END2
{* firebase.init.js *}
firebase.initializeApp(config);
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/config/firebaseConfig.json << END2
{* firebaseConfig.json *}
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/settings.py << END2
{* setting.py *}
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '{* API_BASE_URL *}'
DB_SECRET = '{* API_SECRET_KEY *}'
END2

sudo tee /etc/gitlab/gitlab.rb << END2
external_url 'http://localhost:5001'
registry_external_url 'http://localhost:4567'
registry['notifications'] = [
  {
    'name' => 'Gameserver',
    'url' => 'http://{* API_BASE_URL *}/container_changed',
    'timeout' => '{* NOTI_TIMEOUT *}',
    'threshold' => {* NOTI_THRES *},
    'backoff' => '{* NOTI_BACKOFF *}',
    'headers' => {
      'secret' => ['{* API_SECRET_KEY *}']
    }
  }
]
END2

cd \$VAGRANT_HOME/HTTP-CTF/container-creator/
sudo python create_containers.py -sl ../services -c ctf.json
sudo python create_flag_dirs.py -c ctf.json

cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/{* ctf_name *}/initial_db_state.json

sudo gitlab-ctl reconfigure
cd \$VAGRANT_HOME/HTTP-CTF/gitlab
sudo gitlab-rails console production < gitlab-temp-passwd.sh
python initialize.py -c ../container-creator/ctf.json

cd \$VAGRANT_HOME/HTTP-CTF/container-creator
sudo docker login --username=root --password=temp_passwd {* DOCKER_DISTRIBUTION_SERVER *}
sudo python push_containers.py -sl ../services -c ctf.json -ds localhost -dpo {* DOCKER_DISTRIBUTION_PORT *} -du {* MYSQL_DATABASE_USER *} -dpass {* MYSQL_DATABASE_PASSWORD *}

cd \$VAGRANT_HOME/HTTP-CTF/database
nohup python database_tornado.py &
nohup python gamebot.py &
cd \$VAGRANT_HOME/HTTP-CTF/scorebot
nohup python scorebot.py &
cd \$VAGRANT_HOME/HTTP-CTF/dashboard
nohup python app.py &
END

# Load vagrant box
vagrant destroy -f
vagrant up

# Connect to the vagrant box. You should connected to it to forward ports.
vagrant ssh

