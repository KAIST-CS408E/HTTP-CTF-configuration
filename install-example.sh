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
    v.cpus = 2
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
  config.vm.network "forwarded_port", guest: 4567, host: 14567 # Docker Registry
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
    "num_services": 3,
    "name": "Awesome CTF",
    "services": ["poipoi","sillybox","tattletale"],
    "sudo": true,
    "teams": [{"name":"team1","namespace":"team1"},{"name":"team2","namespace":"team2"},{"name":"team3","namespace":"team3"},{"name":"team4","namespace":"team4"},{"name":"team5","namespace":"team5"}],
    "flag_storage_folder": "/flags",
    "containers_host": "127.0.0.1",
    "containers_ports_start" : 10000
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "awesome-ctf",
  "private_key_id": "fac74c571111beeed5db0d25520d927610e152eb",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCY1+DKxXQybbR6\n43a3k3O5kkp2Xu7Y7YcWBSpwm7a/qbMvu45v76nLEd9vGaEqykKxkQz/aapGCrDv\nDSZvDTIpD1Hi6FlRR9wZ1YRJVSFNTkux6oa+eV8HQaXNAb99zzzcgDgBWkKFnHUL\nwWJHdd0FVXxFUNJoiSinxCq9j095kptOq3JuYHP6ujl2uyqiAHn9T7FSaq+ieV8q\n6TBNAwjkUhvafafpGsZwm2KkVGN+BiY9EjZLiKr+Pp8p/GCRJNB2f+BwEoj0lKDw\nNZIA6FQkCdS90rGVPtGDwpotoDH3GaLH89w1d5UxKkYeYhTYCdGXsQ26xUPGj5SV\nD/fZsD/hAgMBAAECggEAA15qvX1pqLzjR/wgfz5YRCRV0NMZ150wp4sYmt/LwOC4\nKtqq8oupRekQcC3z7/ICU1CbpTuKfb25laNIEBWN3/rO9r3hThnT35vlrQob0Ezj\n/Tlqm+Mn9Yx8X47kzhyVvlRzJ5B6O+CtccNi66lM5FO0iACWiqhPRZdcy83PViIc\n4YdLgQZSDGAzU00F6luYmDYAYv2WqGKxEdM5onQ3SLjsNjHbI4ObHx6bSXKx3IRX\nPzJcy8Rcl+SF46Pv2qaMcCmeMS88/NpE0VHeirpN9H/IRMUm+eIjttiTUHldU0+1\nqpExPnKzHqntLYCcn+kRCSeB6YI0XAEWUgwUnp0DWwKBgQDM8WE6UFosj67cfdwR\nYfA+Zo5dDnpILNdeVh2GnYvQFYNwGrfhdJKqLm7chlTsg/XK7Wj51r2lbBCk58rl\nBHS8xpMNSMsuMTSdys4TunMPcFKbqEf9tO6lPnf+3hoDniy0bPotp05LzZcWEBfv\nXMlxHCqFPcSLxoBhTWANWMOLkwKBgQC+678uZuUJWt9272q2eBBrHn3gzi2b1XL1\nTwcg7OZ58tXy4jsJ0sV+k+wem9SFj22HnEqC4TnmbFJY3gEDSaAzG2bH2JqH2b+Y\nLP3kbXl9RXC6oCUcE91nM0B5+9e9Vf6+/M5Lo7Q33jSqtRg8QDO3BGxhfwUsON5+\nqj3BFmO3OwKBgQCtOKRGZp4hJfzVTugQJSirhYF09AS1Nnl+uejQ3B7NbTGgMmUT\ngbVpdD+t0zi6hDrfH1VoPnIi/LkAuQ5MDj0hRfIK+2kIjPx9FmqiUChqdzTLbiwT\nK7e+IZPI7y8ruajtg2Ld7ZiHB6lZM5cXcOSu3vCtl+yle80M8RprjYgSUwKBgAS7\n4bSr1ngB6dKQIyw9E+MkEWj2k8juZPhSKlIVra1OaSGpnF8k+8KktlEX+hAJu2SG\nao6OORpOi0gq0Qmc1L0Pq9++ri46JvcF/pGgaUfC5gWqnODyWSYK7klYBkRqknN3\n30Ge4IQWHWYyMVSlHuMl1+4e8SjkjBfF7twPyw8rAoGBAMaFTm4YUi4cMNYGZaiP\nG4kcqxSAZi5Ah+rxwSm30RBtCLChqCba3GA1MdKmV8c9X6dpLp9hNoBTKmfBQJks\nwIiVdBh0vDZ9/iQYYSr5lBysMTCQQwrbKgor1V4ari9x5+idVfzJouOGrbPldZSn\ngw3ESqo+GCn570rjeDvp2SG8\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-qmrxe@awesome-ctf.iam.gserviceaccount.com",
  "client_id": "102066288490605912437",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-qmrxe%40awesome-ctf.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/teamConfig.json << END2
{
    "api_secret": "65mnafcwxcm5c2sk",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"cx77lp63kzbpagnc"},"1":{"name":"team2","hashed_password":"pn2w4emghkfzh3bq"},"2":{"name":"team3","hashed_password":"ovqmwgbbpxnarzqz"},"3":{"name":"team4","hashed_password":"zt6bljghvym0c85p"},"4":{"name":"team5","hashed_password":"6enxkbnqfqkoszte"}}
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/static/js/firebase.init.js << END2
// Initialize Firebase
var config = {
    apiKey: "AIzaSyDGbUUg19RhnQC9JSBeFT566NMTyR-bNJk",
    authDomain: "awesome-ctf.firebaseapp.com",
    databaseURL: "https://awesome-ctf.firebaseio.com",
    projectId: "awesome-ctf",
    storageBucket: "awesome-ctf.appspot.com",
    messagingSenderId: "385159914541"
  };
firebase.initializeApp(config);
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "awesome-ctf",
  "private_key_id": "fac74c571111beeed5db0d25520d927610e152eb",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCY1+DKxXQybbR6\n43a3k3O5kkp2Xu7Y7YcWBSpwm7a/qbMvu45v76nLEd9vGaEqykKxkQz/aapGCrDv\nDSZvDTIpD1Hi6FlRR9wZ1YRJVSFNTkux6oa+eV8HQaXNAb99zzzcgDgBWkKFnHUL\nwWJHdd0FVXxFUNJoiSinxCq9j095kptOq3JuYHP6ujl2uyqiAHn9T7FSaq+ieV8q\n6TBNAwjkUhvafafpGsZwm2KkVGN+BiY9EjZLiKr+Pp8p/GCRJNB2f+BwEoj0lKDw\nNZIA6FQkCdS90rGVPtGDwpotoDH3GaLH89w1d5UxKkYeYhTYCdGXsQ26xUPGj5SV\nD/fZsD/hAgMBAAECggEAA15qvX1pqLzjR/wgfz5YRCRV0NMZ150wp4sYmt/LwOC4\nKtqq8oupRekQcC3z7/ICU1CbpTuKfb25laNIEBWN3/rO9r3hThnT35vlrQob0Ezj\n/Tlqm+Mn9Yx8X47kzhyVvlRzJ5B6O+CtccNi66lM5FO0iACWiqhPRZdcy83PViIc\n4YdLgQZSDGAzU00F6luYmDYAYv2WqGKxEdM5onQ3SLjsNjHbI4ObHx6bSXKx3IRX\nPzJcy8Rcl+SF46Pv2qaMcCmeMS88/NpE0VHeirpN9H/IRMUm+eIjttiTUHldU0+1\nqpExPnKzHqntLYCcn+kRCSeB6YI0XAEWUgwUnp0DWwKBgQDM8WE6UFosj67cfdwR\nYfA+Zo5dDnpILNdeVh2GnYvQFYNwGrfhdJKqLm7chlTsg/XK7Wj51r2lbBCk58rl\nBHS8xpMNSMsuMTSdys4TunMPcFKbqEf9tO6lPnf+3hoDniy0bPotp05LzZcWEBfv\nXMlxHCqFPcSLxoBhTWANWMOLkwKBgQC+678uZuUJWt9272q2eBBrHn3gzi2b1XL1\nTwcg7OZ58tXy4jsJ0sV+k+wem9SFj22HnEqC4TnmbFJY3gEDSaAzG2bH2JqH2b+Y\nLP3kbXl9RXC6oCUcE91nM0B5+9e9Vf6+/M5Lo7Q33jSqtRg8QDO3BGxhfwUsON5+\nqj3BFmO3OwKBgQCtOKRGZp4hJfzVTugQJSirhYF09AS1Nnl+uejQ3B7NbTGgMmUT\ngbVpdD+t0zi6hDrfH1VoPnIi/LkAuQ5MDj0hRfIK+2kIjPx9FmqiUChqdzTLbiwT\nK7e+IZPI7y8ruajtg2Ld7ZiHB6lZM5cXcOSu3vCtl+yle80M8RprjYgSUwKBgAS7\n4bSr1ngB6dKQIyw9E+MkEWj2k8juZPhSKlIVra1OaSGpnF8k+8KktlEX+hAJu2SG\nao6OORpOi0gq0Qmc1L0Pq9++ri46JvcF/pGgaUfC5gWqnODyWSYK7klYBkRqknN3\n30Ge4IQWHWYyMVSlHuMl1+4e8SjkjBfF7twPyw8rAoGBAMaFTm4YUi4cMNYGZaiP\nG4kcqxSAZi5Ah+rxwSm30RBtCLChqCba3GA1MdKmV8c9X6dpLp9hNoBTKmfBQJks\nwIiVdBh0vDZ9/iQYYSr5lBysMTCQQwrbKgor1V4ari9x5+idVfzJouOGrbPldZSn\ngw3ESqo+GCn570rjeDvp2SG8\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-qmrxe@awesome-ctf.iam.gserviceaccount.com",
  "client_id": "102066288490605912437",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-qmrxe%40awesome-ctf.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/database/settings.py << END2
DEBUG = True
MYSQL_DATABASE_USER = "root"
MYSQL_DATABASE_INIT_PASSWORD = "http8804"
MYSQL_DATABASE_PASSWORD = "g9g9s30zbhittjzh"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
TICK_TIME_IN_SECONDS = 600
DB_SECRET = "65mnafcwxcm5c2sk"
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = '65mnafcwxcm5c2sk'
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
      'secret' => ['65mnafcwxcm5c2sk']
    }
  }
]
END2

cd \$VAGRANT_HOME/HTTP-CTF/container-creator/
sudo python create_containers.py -sl ../services -c example.json
sudo python create_flag_dirs.py -c example.json

cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/Awesome CTF/initial_db_state.json
sudo gitlab-ctl reconfigure

cd \$VAGRANT_HOME/HTTP-CTF/gitlab
sudo gitlab-rails console production < gitlab-temp-passwd.sh
python initialize.py -c ../container-creator/example.json

cd \$VAGRANT_HOME/HTTP-CTF/container-creator
sudo docker login --username=root --password=temp_passwd localhost:5000
sudo python push_containers.py -sl ../services -c example.json -ds localhost -dpo 5000 -du root -dpass http8804

cd \$VAGRANT_HOME/HTTP-CTF/database
nohup sudo python database_tornado.py &
nohup sudo python gamebot.py &
cd \$VAGRANT_HOME/HTTP-CTF/dashboard
nohup sudo python app.py &
cd \$VAGRANT_HOME/HTTP-CTF/scorebot
nohup sudo python scorebot.py &
END

# Load vagrant box
vagrant destroy -f
vagrant up

# Connect to the vagrant box. You should connected to it to forward ports.
vagrant ssh
