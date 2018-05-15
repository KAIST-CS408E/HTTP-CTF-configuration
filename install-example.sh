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
  "private_key_id": "2b660613792c1f1951d485f33ef5ce89fe558f34",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCakjrRZk9UNDv5\nw8qvZsEiJFotNXWBpmXxMl3UIEF+44Tnwb9g/5hVq0zDQSIizZ3mgVYqDxr+KcPf\nb5E4nDUZ+Bv2VIlNyqmKHi4hngVjPIgi4unzRIA56YN3ng42HnLcbBZzsDGw0+P0\nZlvwrwIBBJ5J7LlWMhcu25nD+4ENKQ7IGy2iqniEJqkqiDO6aFEaXXoNY5z7XmT+\nL/SQTMLGRZyFamfs5q8XmSXD/xavYQJI8y1Bftcw5q058lUgZ2RE9ohbGcocyb7a\n3QbTDE+h9XVIf5baqfZmuF8OW7RXTFNPftgKsd0CAKeF0rZAxcUit7huLeMt/Y85\naJ1g+35XAgMBAAECggEAAWEDQVGmV4aib6yoJunFw1DhCmeLBX2/NGhR9KMtB71u\njBrAYv8kvsQ+dRIkWdHNHNH+kMrTCigZOpRmOUO7fYsnGgrQXBn4v+YGXKpqOzkT\nsIFRu6faylQjphzfh5VnSkF0mdJH6d9EuK4ebTFCf/vTOwRE9a3mDbb2fOHGLvXb\n61dDWdvqrs4GAjE3qvb1rBfKGAUjhOMrBaVpbzUMxvGBd+Gkqm2TJfc5muJeMtD/\nYEnnXr+2Ij0Jajvz3aI3SAUGGYPmpOCJ7+LG2oXnut3AFwQg33GeIMCqLZEgG3jT\n8FlGGS3RFUPuaEbQRDT8qD2qpA1ipuSXzH9VuzJfcQKBgQDUWQ6vYPW/c7AS1f6I\nnErlgyyxAyQEnveLWAmuGWJ4sPEKmPLZzgx9DnX7Hw07BZ2d1MU33EOhPrahUgk2\n08bS0UshdT7ZuRwOR6U0BjBnCu1jt5+UlAtMbs3fa0ClRDViBHdVr3JOye8G/1uu\n9lnDCegPGX5p34EuNeJ82W8o9QKBgQC6WKNliYsJBaU6STNTd3Rrtqj30/+T+I/B\npfWjT5aFDQh+omujsLL5UMhHyXHSYy66lhBVcCRY/xpOMgoPTSzdiSMHyv/w7KW+\nZok7m8ddTkhz5NkNQ3xoILo4BOgeSK6y5OpqONc7IuZG0dNTB+ca9Hkp5Ep1Y9Vm\nFSAnAq+qmwKBgA9oIsOgwlPQvf6v3hblWB3M5ao2Mx/OtOE8Uv95wgZFuEdvj3c0\nFv3f1bmRqDEXGDeCX4jNB28kkLWlsRt0RCG5o7zat+OuJZX3psnehRaE2XJ5uS9b\ninJSO8exDXCwQTtKXaou35lN13TnhCxunVakWlz2GZDu8X171WH/mKwdAoGAGSwi\nHnQ/EN/vWvlKcqr/UhGhr6C2tLFuEfWuQfpdVenVzO155unWs3EjLPdcZdQ6GsBs\nwm3cqx0C269MxpZhSifdUI8ulcgR9694OFIp00Pg667tVypXouVQ4oJfLMAawVXF\nCMZW5MkpHEX56wx1PqHpwCvzlvn+eMS/zCVDv6MCgYEAgewROjzskk+i5vZhlqez\nMAQf+iDJcXRzGDfFrkMqUPuxb/rh5ediaxu5BWizbkH8XNfvqnqx0givLrTWscZv\nqnkOu3qoAxfugzqWfk4G49VqmHW69m53ycWjnAPNFpLAQOyyRclvIe4YC+Ct+wgC\nvmXTi2RMlqmaQNpQ3CEJPx0=\n-----END PRIVATE KEY-----\n",
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
    "api_secret": "riovndpq47vc4913",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"43rwg258gtdjypwe"},"1":{"name":"team2","hashed_password":"v9s88k49boc74dwi"},"2":{"name":"team3","hashed_password":"3jrnhmssag4vlr3v"},"3":{"name":"team4","hashed_password":"lrjvbjigoanq7yof"},"4":{"name":"team5","hashed_password":"l05onygxg3gvbct1"},"5":{"name":"team6","hashed_password":"7s6i21w1p36tj512"}}
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
  "private_key_id": "2b660613792c1f1951d485f33ef5ce89fe558f34",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCakjrRZk9UNDv5\nw8qvZsEiJFotNXWBpmXxMl3UIEF+44Tnwb9g/5hVq0zDQSIizZ3mgVYqDxr+KcPf\nb5E4nDUZ+Bv2VIlNyqmKHi4hngVjPIgi4unzRIA56YN3ng42HnLcbBZzsDGw0+P0\nZlvwrwIBBJ5J7LlWMhcu25nD+4ENKQ7IGy2iqniEJqkqiDO6aFEaXXoNY5z7XmT+\nL/SQTMLGRZyFamfs5q8XmSXD/xavYQJI8y1Bftcw5q058lUgZ2RE9ohbGcocyb7a\n3QbTDE+h9XVIf5baqfZmuF8OW7RXTFNPftgKsd0CAKeF0rZAxcUit7huLeMt/Y85\naJ1g+35XAgMBAAECggEAAWEDQVGmV4aib6yoJunFw1DhCmeLBX2/NGhR9KMtB71u\njBrAYv8kvsQ+dRIkWdHNHNH+kMrTCigZOpRmOUO7fYsnGgrQXBn4v+YGXKpqOzkT\nsIFRu6faylQjphzfh5VnSkF0mdJH6d9EuK4ebTFCf/vTOwRE9a3mDbb2fOHGLvXb\n61dDWdvqrs4GAjE3qvb1rBfKGAUjhOMrBaVpbzUMxvGBd+Gkqm2TJfc5muJeMtD/\nYEnnXr+2Ij0Jajvz3aI3SAUGGYPmpOCJ7+LG2oXnut3AFwQg33GeIMCqLZEgG3jT\n8FlGGS3RFUPuaEbQRDT8qD2qpA1ipuSXzH9VuzJfcQKBgQDUWQ6vYPW/c7AS1f6I\nnErlgyyxAyQEnveLWAmuGWJ4sPEKmPLZzgx9DnX7Hw07BZ2d1MU33EOhPrahUgk2\n08bS0UshdT7ZuRwOR6U0BjBnCu1jt5+UlAtMbs3fa0ClRDViBHdVr3JOye8G/1uu\n9lnDCegPGX5p34EuNeJ82W8o9QKBgQC6WKNliYsJBaU6STNTd3Rrtqj30/+T+I/B\npfWjT5aFDQh+omujsLL5UMhHyXHSYy66lhBVcCRY/xpOMgoPTSzdiSMHyv/w7KW+\nZok7m8ddTkhz5NkNQ3xoILo4BOgeSK6y5OpqONc7IuZG0dNTB+ca9Hkp5Ep1Y9Vm\nFSAnAq+qmwKBgA9oIsOgwlPQvf6v3hblWB3M5ao2Mx/OtOE8Uv95wgZFuEdvj3c0\nFv3f1bmRqDEXGDeCX4jNB28kkLWlsRt0RCG5o7zat+OuJZX3psnehRaE2XJ5uS9b\ninJSO8exDXCwQTtKXaou35lN13TnhCxunVakWlz2GZDu8X171WH/mKwdAoGAGSwi\nHnQ/EN/vWvlKcqr/UhGhr6C2tLFuEfWuQfpdVenVzO155unWs3EjLPdcZdQ6GsBs\nwm3cqx0C269MxpZhSifdUI8ulcgR9694OFIp00Pg667tVypXouVQ4oJfLMAawVXF\nCMZW5MkpHEX56wx1PqHpwCvzlvn+eMS/zCVDv6MCgYEAgewROjzskk+i5vZhlqez\nMAQf+iDJcXRzGDfFrkMqUPuxb/rh5ediaxu5BWizbkH8XNfvqnqx0givLrTWscZv\nqnkOu3qoAxfugzqWfk4G49VqmHW69m53ycWjnAPNFpLAQOyyRclvIe4YC+Ct+wgC\nvmXTi2RMlqmaQNpQ3CEJPx0=\n-----END PRIVATE KEY-----\n",
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
MYSQL_DATABASE_PASSWORD = "05vdk6mlhwz0kbae"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
TICK_TIME_IN_SECONDS = 600
DB_SECRET = "riovndpq47vc4913"
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = 'riovndpq47vc4913'
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
      'secret' => ['riovndpq47vc4913']
    }
  }
]
END2

cd \$VAGRANT_HOME/HTTP-CTF/container-creator/
sudo python create_containers.py -sl ../services -c example.json
sudo python create_flag_dirs.py -c example.json

cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/Awesome-CTF/initial_db_state.json
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
