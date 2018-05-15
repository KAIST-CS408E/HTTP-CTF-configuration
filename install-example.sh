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
    "name": "Awesome CTF",
    "services": ["driller","poipoi","sillybox","tattletale","temperature"],
    "sudo": true,
    "teams": [{"name":"team1","namespace":"team1"},{"name":"team2","namespace":"team2"},{"name":"team3","namespace":"team3"},{"name":"team4","namespace":"team4"}],
    "flag_storage_folder": "/flags",
    "containers_host": "127.0.0.1",
    "containers_ports_start" : 10000
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "http-1661e",
  "private_key_id": "8932b53516590f13928ad4501177f953ed86d8ff",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDBQTDKmR8YiPEd\nMM2K3nRBdjsydhwemrOcSfRsInX6YPe0qnoSuGoXRRmafCGk1rXg5MbOummuw3Ou\nPFp3pizHuLK55SqOP6LhjhGOF7vswQpKX+ncnuziLmft3IVMf04ICJuK+Y24Lt6m\n9OnlgnWOwqN24KGEpXTsfcl4/cKaKKZJhuJ2tMf0ChxHhR/EKFOFnN4/hRfTROiX\nBGK2RQSutIUDG2YT1idKWJCR3P/P2C6z0ZIp2qtUDrFwUBXPSnCY5PFAJLj9stFS\nhukXZZxlculzBCsNI7mri3kxVZvpgFhoMK1XvgfKx6lkhD5yoeK0ay6zv1WVpbY6\nEx6X+Z3JAgMBAAECggEABLA+J2ojK/NAO0EF+Y33pCdtcfuAJ49sAa6LInehulpx\neVWkoBvkf1jxhog8q40Qd6AWln5wBi8EeVLfmdUYnhtOuGMVNFiE9858gfX03Oka\n2hlSg9lWCKTk0quFud3W9iuu9LEPesCQrbGrKNfl3iSTdpS7omt+XHxEP9N940Nu\nl06FPobulpwpbBq5KUdaW+3L9GJB+Vk9fk4My5OZK8ImyLBW/GvQcVjvWQTF7b/n\n1qqzNLv7dYv5DxO477iVDrZlQlWlOEItkBydIMXkfUv7mfPiVIBR2y3BaBOF/0NU\nM4x1VBQOEVs2VI8I6Q1b5RNc9ubp3bnWVipce0RAMQKBgQD456NBtLibgWYbDRD/\nOsqq4S5su98fXDiU4lSLvoZNB9ymMP3wfXK38lt10AgQkPszzJc+6ibgdCwtT1fh\ne58vcOoAg8/R9oPdEq9r6OfoGAQkjIcFP36UMmsW6qcPb1qk5CXdl3qAfKtGKdov\nMPm0Z5kSB8cM4Jq8u/fTEFCaEQKBgQDGw3NGUNw27v6RaR+MDsfpA7l8gfhxuqUQ\nbgDD0hemNjz/kK2Miwkp2uWBVAzTvGXHIibGtDXG/gE2PRZyBDGgadx5ROJJq09R\nsjfNP7dBwNWw/g1qHfcYyzeYjpkD4yycPGZ//cMBVPLxvzYJT9l/tUggUaLB90XM\n6ZHEtcJQOQKBgQCAgL6VjqL8jdrUPnO3AXhernEUbA4ul6MSoqL5nryhilyNZJ/G\nCE4wz6wOb/+p5d/7BzZSofq+SNwB7IO3guZVTNtStrqVcMr1WM8+S/lmpveEkxSm\nTfigtEL7itwDKP9IQA2YkLsLGNIoIDVnxcY1MIMjfuZyLIdWx0iULEkgsQKBgEKt\nVGFVRNqEyA89paCVYMixQCsdapu0UiU10bnfI6HVdhcBkMah6ZwJ243MBVWOUNJB\niaKE17l+gieQzJPJBmDawmRIEGVIO56bW47V/gLnzofGYfekP70ohuj9hSVBszhi\nJrxvA1jSB4HDdDwhdkQaKyz0VdYdvmOkQwsrMhk5AoGACYqRxCAomKgTV++1gfug\nhq5DBVwZJSQ01EgrasDO+ZojlTskYgBePwz5exO7KhUyIgg/alVshMMxr/BH2jeM\ngZwlqvbtuVCOLgXaT84tRgAwHu8ssgo1silEBOu/FU3jSqpVxyfFcwtmSNCk+otR\nWS5kk3Buf1ywotBFRmko4ug=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-ryz10@http-1661e.iam.gserviceaccount.com",
  "client_id": "112948171011989343622",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-ryz10%40http-1661e.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/teamConfig.json << END2
{
    "api_secret": "YOUKNOWSOMETHINGYOUSUCK",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"w4ex4a6zz5xe2hp0"},"1":{"name":"team2","hashed_password":"wkjtzeuk2bgzslhr"},"2":{"name":"team3","hashed_password":"d9ov9uwf6k3bnxqy"},"3":{"name":"team4","hashed_password":"7wjusqda94nvjro6"}}
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
  "private_key_id": "8932b53516590f13928ad4501177f953ed86d8ff",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDBQTDKmR8YiPEd\nMM2K3nRBdjsydhwemrOcSfRsInX6YPe0qnoSuGoXRRmafCGk1rXg5MbOummuw3Ou\nPFp3pizHuLK55SqOP6LhjhGOF7vswQpKX+ncnuziLmft3IVMf04ICJuK+Y24Lt6m\n9OnlgnWOwqN24KGEpXTsfcl4/cKaKKZJhuJ2tMf0ChxHhR/EKFOFnN4/hRfTROiX\nBGK2RQSutIUDG2YT1idKWJCR3P/P2C6z0ZIp2qtUDrFwUBXPSnCY5PFAJLj9stFS\nhukXZZxlculzBCsNI7mri3kxVZvpgFhoMK1XvgfKx6lkhD5yoeK0ay6zv1WVpbY6\nEx6X+Z3JAgMBAAECggEABLA+J2ojK/NAO0EF+Y33pCdtcfuAJ49sAa6LInehulpx\neVWkoBvkf1jxhog8q40Qd6AWln5wBi8EeVLfmdUYnhtOuGMVNFiE9858gfX03Oka\n2hlSg9lWCKTk0quFud3W9iuu9LEPesCQrbGrKNfl3iSTdpS7omt+XHxEP9N940Nu\nl06FPobulpwpbBq5KUdaW+3L9GJB+Vk9fk4My5OZK8ImyLBW/GvQcVjvWQTF7b/n\n1qqzNLv7dYv5DxO477iVDrZlQlWlOEItkBydIMXkfUv7mfPiVIBR2y3BaBOF/0NU\nM4x1VBQOEVs2VI8I6Q1b5RNc9ubp3bnWVipce0RAMQKBgQD456NBtLibgWYbDRD/\nOsqq4S5su98fXDiU4lSLvoZNB9ymMP3wfXK38lt10AgQkPszzJc+6ibgdCwtT1fh\ne58vcOoAg8/R9oPdEq9r6OfoGAQkjIcFP36UMmsW6qcPb1qk5CXdl3qAfKtGKdov\nMPm0Z5kSB8cM4Jq8u/fTEFCaEQKBgQDGw3NGUNw27v6RaR+MDsfpA7l8gfhxuqUQ\nbgDD0hemNjz/kK2Miwkp2uWBVAzTvGXHIibGtDXG/gE2PRZyBDGgadx5ROJJq09R\nsjfNP7dBwNWw/g1qHfcYyzeYjpkD4yycPGZ//cMBVPLxvzYJT9l/tUggUaLB90XM\n6ZHEtcJQOQKBgQCAgL6VjqL8jdrUPnO3AXhernEUbA4ul6MSoqL5nryhilyNZJ/G\nCE4wz6wOb/+p5d/7BzZSofq+SNwB7IO3guZVTNtStrqVcMr1WM8+S/lmpveEkxSm\nTfigtEL7itwDKP9IQA2YkLsLGNIoIDVnxcY1MIMjfuZyLIdWx0iULEkgsQKBgEKt\nVGFVRNqEyA89paCVYMixQCsdapu0UiU10bnfI6HVdhcBkMah6ZwJ243MBVWOUNJB\niaKE17l+gieQzJPJBmDawmRIEGVIO56bW47V/gLnzofGYfekP70ohuj9hSVBszhi\nJrxvA1jSB4HDdDwhdkQaKyz0VdYdvmOkQwsrMhk5AoGACYqRxCAomKgTV++1gfug\nhq5DBVwZJSQ01EgrasDO+ZojlTskYgBePwz5exO7KhUyIgg/alVshMMxr/BH2jeM\ngZwlqvbtuVCOLgXaT84tRgAwHu8ssgo1silEBOu/FU3jSqpVxyfFcwtmSNCk+otR\nWS5kk3Buf1ywotBFRmko4ug=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-ryz10@http-1661e.iam.gserviceaccount.com",
  "client_id": "112948171011989343622",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-ryz10%40http-1661e.iam.gserviceaccount.com"
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
TICK_TIME_IN_SECONDS=600
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
