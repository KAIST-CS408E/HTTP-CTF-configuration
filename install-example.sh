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
    "name": "Awesome-CTF",
    "services": ["poipoi","sillybox","tattletale"],
    "sudo": true,
    "teams": [{"name":"team1","namespace":"team1"},{"name":"team2","namespace":"team2"},{"name":"team3","namespace":"team3"},{"name":"team4","namespace":"team4"},{"name":"team5","namespace":"team5"},{"name":"team6","namespace":"team6"}],
    "flag_storage_folder": "/flags",
    "containers_host": "127.0.0.1",
    "containers_ports_start" : 10000
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "awesome-ctf",
  "private_key_id": "b315905ef1f9c3f37ea74c80b36dac2d4d3deac1",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDAro50oKNsB2q1\nrP5Pgm+oeeitv+pm2o2+x/CS/KQ9blUQ5oJtK867fICjg484mF+Y9CIa/CE+5lPE\n/QYRYKRs9baj65bjTCefjs2roWm69H0xzFTFFGqlT7TYV7DCP6QuFsYH1kG57ER9\nLXugHdEVg8sJNUk9QEDprqJgQoFsKQPznKMLpxeLRf960Kk9LT1sF8tthhlvSK8F\nWQGXnq+RyKVxEHiiZjqqgqgZfxhwdkO+ZtfKymM/xhQ0fHvHX417Ctd7wFc/mJzf\neNaEjVOW+bpAlouxuM/K12+yKCJdCj7LK0RwvXempold/ZfiBOGwjY4KD9yK7WAM\nKJsFhPnFAgMBAAECggEAAN5JF4g89AEHpLQvQyFIYD3Z/+FI0y4ts4K2g9rEPmIC\nKp6YLqei90VY6rr+sIiAfWvUcXGBoM+6PA8tVZiMuTbCul762IU2zMCOnw/FvqGj\nMFuY9ha6gqryn14NuYLO33s0/do/4YWCrXdMV5GWLNDRgp/sAPZJQ7pvCjhInSch\ngb2CyLzqBH+rJDPP7YoF2wkGvt7CbtfcvVLKs1ILDWuH7DXfv+2QO3AYd4LXbBJ+\n6np/fPL20ItA7boFZXnGvTjVxDwHtWx/vpvZky4LHEtM3Ox15hnZpoll/J7NKRBQ\nY//JNcz4VTn+IjZ1Ss3LCmi3dz5f5QfSfysk+0ohUQKBgQDnz9SAVCI63Tb7oLdv\nFTPiK57gofF0DWGKXZYfHn7ha3pU7OYM7WicyVWI3MDkxFRLhTHPD4JOVs/kk3WT\nnAcuxd95+M1ds0aXgM3xbiHm1wCE6l6DqrkhrLinKHfB/uVo8JX8M/7r6uRmGpJb\nQIUig/f6/4KjtINzSTSf8xgMeQKBgQDUyXwEPeAy+rBNGUwrVB8bRz2/HHMO9RNH\nVw7R7BaV3tkZyux6fP/Pdb0oZ2YCv7T/mQ5jPZ67Hg+9w2VsmMabcuGF7F8lhPw5\n+nIX+ZYYito4vm+lKm6ud8TT4nvnakkdiw/bRnpEdAcHQr+QrFjJ2YqonKMKTyM7\nj/j/Da3srQKBgCiGU67vhmBmBdOtgAPiYASc/ZRlmzFfmXq366ObEDFWObeZBoqi\nAlTOea6IcQxNKjNdoJyDKJOLZ6KdCMP6VeMeYngPP8+upJudv+MCDtktIwEZe9Zm\nxSCW8lz+nRkD95UF4iKJ8HnLwYv7/zQGrn+fNH3jpzH5P7WqyZFgzQZ5AoGAQEBa\npzk70ojp5U3nNwoennEDjwp7H6AW4yrBedes9jIlIempQE8wOyeVJ3cZUWkrsSY5\nNvQrUtr/68/tdz4mclfdC0BVdpHSS3t5Kg4eKWj7/bhbI+dNJndZwpUXzsfELhyI\nfDCqyLK0UJfyGjBAWyrJ+KHbhUhiHiEaEYHC670CgYAbGNoToOL7sTxRHGiWM/aU\nmC2G1uVv7ATj4Un62E9Ib6MFzKfs18D2i1rGhus3OFFICKuL74f1VAgpAAeYcuue\nwxNeF0Ap8Xez7HKlwlbAoIdACMBDbSLrow/1f8nBxYVYxhIB8J+aCALszPSleoIw\nfps5TGSX3eMs3818QNQb8A==\n-----END PRIVATE KEY-----\n",
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
    "api_secret": "939oawae813bcg8h",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"04qckvfk0fcszl9m"},"1":{"name":"team2","hashed_password":"v40clpd6qvm6m269"},"2":{"name":"team3","hashed_password":"38ie9omvsbnoa74w"},"3":{"name":"team4","hashed_password":"s51tmsgq1sdoegbi"},"4":{"name":"team5","hashed_password":"k1wtsyhguwju33jt"},"5":{"name":"team6","hashed_password":"ernwi7i1f8lhw2tq"}}
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
  "private_key_id": "b315905ef1f9c3f37ea74c80b36dac2d4d3deac1",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDAro50oKNsB2q1\nrP5Pgm+oeeitv+pm2o2+x/CS/KQ9blUQ5oJtK867fICjg484mF+Y9CIa/CE+5lPE\n/QYRYKRs9baj65bjTCefjs2roWm69H0xzFTFFGqlT7TYV7DCP6QuFsYH1kG57ER9\nLXugHdEVg8sJNUk9QEDprqJgQoFsKQPznKMLpxeLRf960Kk9LT1sF8tthhlvSK8F\nWQGXnq+RyKVxEHiiZjqqgqgZfxhwdkO+ZtfKymM/xhQ0fHvHX417Ctd7wFc/mJzf\neNaEjVOW+bpAlouxuM/K12+yKCJdCj7LK0RwvXempold/ZfiBOGwjY4KD9yK7WAM\nKJsFhPnFAgMBAAECggEAAN5JF4g89AEHpLQvQyFIYD3Z/+FI0y4ts4K2g9rEPmIC\nKp6YLqei90VY6rr+sIiAfWvUcXGBoM+6PA8tVZiMuTbCul762IU2zMCOnw/FvqGj\nMFuY9ha6gqryn14NuYLO33s0/do/4YWCrXdMV5GWLNDRgp/sAPZJQ7pvCjhInSch\ngb2CyLzqBH+rJDPP7YoF2wkGvt7CbtfcvVLKs1ILDWuH7DXfv+2QO3AYd4LXbBJ+\n6np/fPL20ItA7boFZXnGvTjVxDwHtWx/vpvZky4LHEtM3Ox15hnZpoll/J7NKRBQ\nY//JNcz4VTn+IjZ1Ss3LCmi3dz5f5QfSfysk+0ohUQKBgQDnz9SAVCI63Tb7oLdv\nFTPiK57gofF0DWGKXZYfHn7ha3pU7OYM7WicyVWI3MDkxFRLhTHPD4JOVs/kk3WT\nnAcuxd95+M1ds0aXgM3xbiHm1wCE6l6DqrkhrLinKHfB/uVo8JX8M/7r6uRmGpJb\nQIUig/f6/4KjtINzSTSf8xgMeQKBgQDUyXwEPeAy+rBNGUwrVB8bRz2/HHMO9RNH\nVw7R7BaV3tkZyux6fP/Pdb0oZ2YCv7T/mQ5jPZ67Hg+9w2VsmMabcuGF7F8lhPw5\n+nIX+ZYYito4vm+lKm6ud8TT4nvnakkdiw/bRnpEdAcHQr+QrFjJ2YqonKMKTyM7\nj/j/Da3srQKBgCiGU67vhmBmBdOtgAPiYASc/ZRlmzFfmXq366ObEDFWObeZBoqi\nAlTOea6IcQxNKjNdoJyDKJOLZ6KdCMP6VeMeYngPP8+upJudv+MCDtktIwEZe9Zm\nxSCW8lz+nRkD95UF4iKJ8HnLwYv7/zQGrn+fNH3jpzH5P7WqyZFgzQZ5AoGAQEBa\npzk70ojp5U3nNwoennEDjwp7H6AW4yrBedes9jIlIempQE8wOyeVJ3cZUWkrsSY5\nNvQrUtr/68/tdz4mclfdC0BVdpHSS3t5Kg4eKWj7/bhbI+dNJndZwpUXzsfELhyI\nfDCqyLK0UJfyGjBAWyrJ+KHbhUhiHiEaEYHC670CgYAbGNoToOL7sTxRHGiWM/aU\nmC2G1uVv7ATj4Un62E9Ib6MFzKfs18D2i1rGhus3OFFICKuL74f1VAgpAAeYcuue\nwxNeF0Ap8Xez7HKlwlbAoIdACMBDbSLrow/1f8nBxYVYxhIB8J+aCALszPSleoIw\nfps5TGSX3eMs3818QNQb8A==\n-----END PRIVATE KEY-----\n",
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
MYSQL_DATABASE_PASSWORD = "hoiyjscetzmw260m"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
TICK_TIME_IN_SECONDS = 100
DB_SECRET = "939oawae813bcg8h"
GAME_ROUND = 200
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = '939oawae813bcg8h'
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
      'secret' => ['939oawae813bcg8h']
    }
  }
]
END2

tee \$VAGRANT_HOME/HTTP-CTF/gitlab/config.json << END2
{
    "teams": {"0":{"name":"team1","hashed_password":"04qckvfk0fcszl9m"},"1":{"name":"team2","hashed_password":"v40clpd6qvm6m269"},"2":{"name":"team3","hashed_password":"38ie9omvsbnoa74w"},"3":{"name":"team4","hashed_password":"s51tmsgq1sdoegbi"},"4":{"name":"team5","hashed_password":"k1wtsyhguwju33jt"},"5":{"name":"team6","hashed_password":"ernwi7i1f8lhw2tq"}}
}
END2

cd \$VAGRANT_HOME/HTTP-CTF/container-creator/
sudo python create_containers.py -sl ../services -c example.json
sudo python create_flag_dirs.py -c example.json

cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/Awesome-CTF/initial_db_state.json
sudo gitlab-ctl reconfigure

cd \$VAGRANT_HOME/HTTP-CTF/gitlab
sudo gitlab-rails console production < gitlab-temp-passwd.sh
python initialize.py -c config.json

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
