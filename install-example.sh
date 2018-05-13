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
tee \$VAGRANT_HOME/HTTP-CTF/container-creator/example.json << END2
{
    "num_services": 5,
    "name": "Test CTF",
    "services": ["driller", "poipoi", "sillybox", "tattletale", "temperature"],
    "sudo": true,
    "teams": [
        {
            "name": "team1",
            "namespace": "team1"
        },
        {
            "name": "team2",
            "namespace": "team2"
        }
    ],
    "flag_storage_folder": "/flags",
    "containers_host": "127.0.0.1",
    "containers_ports_start" : 10000
}
END2
tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "http-1661e",
  "private_key_id": "ffe83cb140ac1650fcd3d470cad6b9dedfa8ab9a",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC26DetPe6e2pKh\nVm5irxT8jJuHaZiugzwzK2b9q4in8kvsqsl6e/L49vP8O3B/PCfhoxxcT/2z+Blw\nf6PL1/BAZ1oAnvSOVTbF2HCrRrjUeN/pt3Fijv9HGb+q6ZDLjF5vm7fzt2nfu8bv\nQxJeZYEh75wyllOyOpkG3wvgliq5WUjR0VDBvkFJ3iXIeXFSPkSC5ZTW4cBiapuy\nl0dDzbO2iVLgKwSMGmI0JtPiFW21RRM8forHXKDUPYjZo/PhWl6mMI6FNHMRdMZP\nxiqgaTV4kIdl14VtlxYc9X9b6WYpGacxArS6pgoSlkfKLyefvWauCCa/eHUwOGGG\nf46CWSd3AgMBAAECggEAUS4lFAOyZpgNT4Vcjfk2X9cKaqIQDZiavf1MA1fAWgY8\n84hjzzS3RQ/af39kMVyiOM/b1Q79xARgSiGkseMgM32LoU3rrkac/lfPvf0wKMGT\nZBiyvvNH0ydW/gUXanhdK70Z+pZT6+TcaTJEM1hq5YSDN6Kn+Clw5O9XRrFvuf5o\nwjEjJavYDzEH6mX6SSUK5KX4eyLBfqEh2+C16lPsq5u+72OS8AWtwT4B/1ReuM2K\n7SdMaLPZzGgTnmIk9C4Kwi+fyddE5wH4wlFXSwW4fVLIIot0qzTa0PTqSzGTtMFt\n4UZkRom18gWV+bWIdAFijy+fN6eQ3yzhFpXvQNvtqQKBgQD0gOux7Yxniz/eW9Lx\nYBzU64PnYSKse+4D31cKtGlSEQ9lwKEG5pelikrlSzz/hyjipaNVbdnEIQ9y+wCk\nu4ocorCFyJ6VX3OSlynRvHyxrhKXGydBva+S8dj1rEa2BIjcYnMmB1whhH5DokUB\nki7NydJythBuJ6A8fO4Wp95EKQKBgQC/gdzG3LATy7+lrN9ZMr2Q3Kj6XegexUd/\nHcBEWURmBAxqJkNPrhqXiFwtss62rnZHkAm0JWcC4GRbVQkv23C/5tBvqR8Vy4mf\n3ZwAxW2d9eDu2ZOuYW8j9eO8+R7wAAyGVCLTG2MuRBcOlAEisMzLJiwCgRovv9oB\nP4/28TCCnwKBgAtXb5dxTXIAI5ZM7BwGOVAnHJc/Cjy2AvRrB76XX8tOv0gZB18q\nkx46q/623r17p4nb5RexYMiYP/81ZXI+wMlTQpzyEWkcZGAIYwg3lhEn4fTgbZG/\nGsXWMhozQ5Rt4WtXpb+916g2XSUGAe1wunsRQZHQoDJ75BLqOKEUaFsBAoGARHrg\ngq/purpyBoFhwJi3VrTBK/4mgdJTta3i0c4F+mDaO58BFN4SHjuhkqnM52BNZVup\nTKTPSCULXelzhox2rfiQck1Mk1OcG/F31oLCpuiEjYR6HbIztu03iZyfpnyt/d7a\nMRkrByFMCWd9XHVSVhaJSD/4KDj3cNjU1x36FcsCgYEA4mzY1CsVRrobvEudlX5O\nbZp9lIBcHq/sCQjeD5Mieknmhi2Aqdh2Q0MkZqMq+uLz556J+T2hKTxWFBCWetlg\nZW0fe4eGH771l2qmBZQbK0SjhQMLOVz1UHg1fYZbOtI09famD2RKI70CyWCMjacr\n9i3rUHoEGgEY1nCWu7DtE5U=\n-----END PRIVATE KEY-----\n",
  "client_email": "http-1661e@appspot.gserviceaccount.com",
  "client_id": "103491681279373200481",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/http-1661e%40appspot.gserviceaccount.com"
}
END2
tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/teamConfig.json << END2
{
    "api_secret": "YOUKNOWSOMETHINGYOUSUCK",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {
        "1": {
            "hashed_password": "hi",
            "name": "Hi"
        },
        "2": {
            "hashed_password": "hi",
            "name": "Sheep"
        },
        "3": {
            "hashed_password": "asdf",
            "name": "asdf"
        }
    }
}
END2
tee \$VAGRANT_HOME/HTTP-CTF/dashboard/static/js/firebase.init.js << END2
// Initialize Firebase
var config = {
    apiKey: "AIzaSyDt1YJ0PuIc6Xz3KLm5Z6NJSgZPXH_ZXT0",
    authDomain: "http-1661e.firebaseapp.com",
    databaseURL: "https://http-1661e.firebaseio.com",
    projectId: "http-1661e",
    storageBucket: "http-1661e.appspot.com",
    messagingSenderId: "584427206756"
};
firebase.initializeApp(config);
END2
tee \$VAGRANT_HOME/HTTP-CTF/database/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "http-1661e",
  "private_key_id": "ffe83cb140ac1650fcd3d470cad6b9dedfa8ab9a",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC26DetPe6e2pKh\nVm5irxT8jJuHaZiugzwzK2b9q4in8kvsqsl6e/L49vP8O3B/PCfhoxxcT/2z+Blw\nf6PL1/BAZ1oAnvSOVTbF2HCrRrjUeN/pt3Fijv9HGb+q6ZDLjF5vm7fzt2nfu8bv\nQxJeZYEh75wyllOyOpkG3wvgliq5WUjR0VDBvkFJ3iXIeXFSPkSC5ZTW4cBiapuy\nl0dDzbO2iVLgKwSMGmI0JtPiFW21RRM8forHXKDUPYjZo/PhWl6mMI6FNHMRdMZP\nxiqgaTV4kIdl14VtlxYc9X9b6WYpGacxArS6pgoSlkfKLyefvWauCCa/eHUwOGGG\nf46CWSd3AgMBAAECggEAUS4lFAOyZpgNT4Vcjfk2X9cKaqIQDZiavf1MA1fAWgY8\n84hjzzS3RQ/af39kMVyiOM/b1Q79xARgSiGkseMgM32LoU3rrkac/lfPvf0wKMGT\nZBiyvvNH0ydW/gUXanhdK70Z+pZT6+TcaTJEM1hq5YSDN6Kn+Clw5O9XRrFvuf5o\nwjEjJavYDzEH6mX6SSUK5KX4eyLBfqEh2+C16lPsq5u+72OS8AWtwT4B/1ReuM2K\n7SdMaLPZzGgTnmIk9C4Kwi+fyddE5wH4wlFXSwW4fVLIIot0qzTa0PTqSzGTtMFt\n4UZkRom18gWV+bWIdAFijy+fN6eQ3yzhFpXvQNvtqQKBgQD0gOux7Yxniz/eW9Lx\nYBzU64PnYSKse+4D31cKtGlSEQ9lwKEG5pelikrlSzz/hyjipaNVbdnEIQ9y+wCk\nu4ocorCFyJ6VX3OSlynRvHyxrhKXGydBva+S8dj1rEa2BIjcYnMmB1whhH5DokUB\nki7NydJythBuJ6A8fO4Wp95EKQKBgQC/gdzG3LATy7+lrN9ZMr2Q3Kj6XegexUd/\nHcBEWURmBAxqJkNPrhqXiFwtss62rnZHkAm0JWcC4GRbVQkv23C/5tBvqR8Vy4mf\n3ZwAxW2d9eDu2ZOuYW8j9eO8+R7wAAyGVCLTG2MuRBcOlAEisMzLJiwCgRovv9oB\nP4/28TCCnwKBgAtXb5dxTXIAI5ZM7BwGOVAnHJc/Cjy2AvRrB76XX8tOv0gZB18q\nkx46q/623r17p4nb5RexYMiYP/81ZXI+wMlTQpzyEWkcZGAIYwg3lhEn4fTgbZG/\nGsXWMhozQ5Rt4WtXpb+916g2XSUGAe1wunsRQZHQoDJ75BLqOKEUaFsBAoGARHrg\ngq/purpyBoFhwJi3VrTBK/4mgdJTta3i0c4F+mDaO58BFN4SHjuhkqnM52BNZVup\nTKTPSCULXelzhox2rfiQck1Mk1OcG/F31oLCpuiEjYR6HbIztu03iZyfpnyt/d7a\nMRkrByFMCWd9XHVSVhaJSD/4KDj3cNjU1x36FcsCgYEA4mzY1CsVRrobvEudlX5O\nbZp9lIBcHq/sCQjeD5Mieknmhi2Aqdh2Q0MkZqMq+uLz556J+T2hKTxWFBCWetlg\nZW0fe4eGH771l2qmBZQbK0SjhQMLOVz1UHg1fYZbOtI09famD2RKI70CyWCMjacr\n9i3rUHoEGgEY1nCWu7DtE5U=\n-----END PRIVATE KEY-----\n",
  "client_email": "http-1661e@appspot.gserviceaccount.com",
  "client_id": "103491681279373200481",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/http-1661e%40appspot.gserviceaccount.com"
}
END2
tee \$VAGRANT_HOME/HTTP-CTF/database/settings.py << END2
DEBUG = True
MYSQL_DATABASE_USER = "root"
MYSQL_DATABASE_PASSWORD = "http8804"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
END2
tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = 'YOUKNOWSOMETHINGYOUSUCK'
END2
sudo tee /etc/gitlab/gitlab.rb << END2
external_url 'http://localhost:5001'
registry_external_url 'http://localhost:4567'
registry['notifications'] = [
  {
    'name' => 'Gameserver',
    'url' => 'http://localhost:4000/container_changed',
    'timeout' => '1s',
    'threshold' => 5,
    'backoff' => '2s',
    'headers' => {
      'secret' => ['YOUKNOWSOMETHINGYOUSUCK']
    }
  }
]
END2
cd \$VAGRANT_HOME/HTTP-CTF/container-creator/
sudo python create_containers.py -sl ../services -c example.json
sudo python create_flag_dirs.py -c example.json
cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/Test\ CTF/initial_db_state.json
sudo gitlab-ctl reconfigure
cd \$VAGRANT_HOME/HTTP-CTF/gitlab
sudo gitlab-rails console production < gitlab-temp-passwd.sh
python initialize.py -c ../container-creator/example.json
cd \$VAGRANT_HOME/HTTP-CTF/container-creator
sudo docker login --username=root --password=temp_passwd localhost:5000
sudo python push_containers.py -sl ../services -c example.json -ds localhost -dpo 5000 -du root -dpass http8804
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