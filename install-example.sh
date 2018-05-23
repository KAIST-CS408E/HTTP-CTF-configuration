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
    "teams": [{"name":"team1","namespace":"team1"},{"name":"team2","namespace":"team2"},{"name":"team3","namespace":"team3"},{"name":"team4","namespace":"team4"},{"name":"team5","namespace":"team5"}],
    "flag_storage_folder": "/flags",
    "containers_host": "127.0.0.1",
    "containers_ports_start" : 10000,
    "round" : 200
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "awesome-ctf",
  "private_key_id": "b117985cf3cff9037dc0cbdaecabb85437a29c35",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUJmZaINK4L0TH\njNmW8OkL3MplPmUaGpFknaKA0sHgaovesj+ze/VvLjCh8q4INOQGLMC05dQjfS1+\nlQphi9sQR1vgJRXYyD6F78uBqhu/SbIXbdVUnj5f9AxibNBXGRoKr8Wg8MMWIHnK\n6JkH/LdTYlDZ6nZVyi/d7hJzIYX0+1wLphF3ojdtOoINLRdOVmF4UmMV3u04qdgs\nV4MoarFSqdqYpWCaW2c2xPXXy6a8Nlmp/lcVHnaePf9aup5+hE/y5b5Ajj7IB5ps\nGw0lcBM7HcKGTeM3kYGP6xJ5QRH0TmrUSu7Rquu2HH4JCevugqlMohkMKChNCD7u\nJKg3v0otAgMBAAECggEACPr+QxCphYfI7uX/dxbrm+QNqbYpj66nVyofwnJ+0oIF\ncpxQJgDjF0f4036d71WqRrijlsvgQbIbuD1cN5TfkC/1HXU7ii8FKE8tab0RsWZe\nHVpyqrT9e2Xmo9zcqjbBXTtVWlSBbZuwjCc46Hr7Cz12MHw2HUY9V5iPAu7cy+ny\ncD5Kl6UeZRblJSEEsLFDJrWqogvk8upkpLDzmhQmrqrXhGmDu6c8emKDt5X4mng9\nUREnpBUC/POwpUZbrnrD1l11R+zNsvjctGQHucFyxu/zy3pFpbTUEJKK4jNSexGh\nLAQkAq52v3aMb5pmal0Cw2A2SZerdodvp+6BQYzy4QKBgQD+KRXrRslQ3iUls0T0\nG6Rl2r7Gc5mubF7xBQOcSVuyKfdLtQ2jMTKztxMkDpAQ9aZ5J2kIWkQzeCDcxO8D\nnVTJtktSpZ2nDbMr/J1NejzRKbmWeifbynSMTYOeduhxuzau2D56q0kRO/PFHcu9\nMafIXjZvPImCbqXxldhd6lBGRwKBgQDVr3nnodKE/dI434frGV/ZaehNQpnn4RsK\ngkTyPT7+PiEhnlm3MTClPazouSoDpgCZWxswY7kLw85I4kCl/62hCWHQksqBmhAN\naEmHcJuq8TtRTGNxpoxZPdtyGFSVtU8ztlROHfOP3JeroysW68kEKpkyoFDU9ARj\nDs8sr7OB6wKBgQDzxWBamzg3sfmbIUh/gYu6jYXxPasnGpYtQYvm+I1UYt/n4y3D\nWkqxCGT5bmZLffE/vscE1d8YJp4OYWyF4P8TwR6ZlHOTaJZzGAWf7CAs1YJFi8Bz\nFMmYUDhvYskrXE7kgE/cxDB+sSvr4doqClhM2+AF7OBPE+Vhw0EVQsnfvQKBgCPB\nRu6hPy6Noh1uGboW9tjURdCXslUAb5vkjFDUOrQkBTsw2eYzTuZ3WXVfdk5B+puu\niPAh35a+XsgHQ7YDADSP81QJG+Vvt/vmVVdaWlHSJ5DE7WbY7WcJWKzQsWaTffsz\nKQwhKt4JlT9dABrHvUz7K8My3BOl+Q3yLmxVwf2dAoGBANg95E0D9B4ZhZOZtbKN\najMmU0a9vcQP0IG5/GSmBbboJ212r73zCm/IJDYeClW1vC3bfQjdrTRKPxqNpgYV\ngDjcGJEk5Hk4h2gba+9L4L0ecWSgKmfzk407fMYUUkjFfzBjLMnk0+5broI7YzPz\n01nYxQqDr/iJ7JSpJ8leac5d\n-----END PRIVATE KEY-----\n",
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
    "api_secret": "8qgq4c34i51gnm17",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"h2pkp0gs9338kp1b"},"1":{"name":"team2","hashed_password":"1sx8yjkqz63stmgr"},"2":{"name":"team3","hashed_password":"h5t04gtxpsyzdzeo"},"3":{"name":"team4","hashed_password":"g8u5xgjp48fip42a"},"4":{"name":"team5","hashed_password":"cny3jiqazap2riad"}}
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
  "private_key_id": "b117985cf3cff9037dc0cbdaecabb85437a29c35",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDUJmZaINK4L0TH\njNmW8OkL3MplPmUaGpFknaKA0sHgaovesj+ze/VvLjCh8q4INOQGLMC05dQjfS1+\nlQphi9sQR1vgJRXYyD6F78uBqhu/SbIXbdVUnj5f9AxibNBXGRoKr8Wg8MMWIHnK\n6JkH/LdTYlDZ6nZVyi/d7hJzIYX0+1wLphF3ojdtOoINLRdOVmF4UmMV3u04qdgs\nV4MoarFSqdqYpWCaW2c2xPXXy6a8Nlmp/lcVHnaePf9aup5+hE/y5b5Ajj7IB5ps\nGw0lcBM7HcKGTeM3kYGP6xJ5QRH0TmrUSu7Rquu2HH4JCevugqlMohkMKChNCD7u\nJKg3v0otAgMBAAECggEACPr+QxCphYfI7uX/dxbrm+QNqbYpj66nVyofwnJ+0oIF\ncpxQJgDjF0f4036d71WqRrijlsvgQbIbuD1cN5TfkC/1HXU7ii8FKE8tab0RsWZe\nHVpyqrT9e2Xmo9zcqjbBXTtVWlSBbZuwjCc46Hr7Cz12MHw2HUY9V5iPAu7cy+ny\ncD5Kl6UeZRblJSEEsLFDJrWqogvk8upkpLDzmhQmrqrXhGmDu6c8emKDt5X4mng9\nUREnpBUC/POwpUZbrnrD1l11R+zNsvjctGQHucFyxu/zy3pFpbTUEJKK4jNSexGh\nLAQkAq52v3aMb5pmal0Cw2A2SZerdodvp+6BQYzy4QKBgQD+KRXrRslQ3iUls0T0\nG6Rl2r7Gc5mubF7xBQOcSVuyKfdLtQ2jMTKztxMkDpAQ9aZ5J2kIWkQzeCDcxO8D\nnVTJtktSpZ2nDbMr/J1NejzRKbmWeifbynSMTYOeduhxuzau2D56q0kRO/PFHcu9\nMafIXjZvPImCbqXxldhd6lBGRwKBgQDVr3nnodKE/dI434frGV/ZaehNQpnn4RsK\ngkTyPT7+PiEhnlm3MTClPazouSoDpgCZWxswY7kLw85I4kCl/62hCWHQksqBmhAN\naEmHcJuq8TtRTGNxpoxZPdtyGFSVtU8ztlROHfOP3JeroysW68kEKpkyoFDU9ARj\nDs8sr7OB6wKBgQDzxWBamzg3sfmbIUh/gYu6jYXxPasnGpYtQYvm+I1UYt/n4y3D\nWkqxCGT5bmZLffE/vscE1d8YJp4OYWyF4P8TwR6ZlHOTaJZzGAWf7CAs1YJFi8Bz\nFMmYUDhvYskrXE7kgE/cxDB+sSvr4doqClhM2+AF7OBPE+Vhw0EVQsnfvQKBgCPB\nRu6hPy6Noh1uGboW9tjURdCXslUAb5vkjFDUOrQkBTsw2eYzTuZ3WXVfdk5B+puu\niPAh35a+XsgHQ7YDADSP81QJG+Vvt/vmVVdaWlHSJ5DE7WbY7WcJWKzQsWaTffsz\nKQwhKt4JlT9dABrHvUz7K8My3BOl+Q3yLmxVwf2dAoGBANg95E0D9B4ZhZOZtbKN\najMmU0a9vcQP0IG5/GSmBbboJ212r73zCm/IJDYeClW1vC3bfQjdrTRKPxqNpgYV\ngDjcGJEk5Hk4h2gba+9L4L0ecWSgKmfzk407fMYUUkjFfzBjLMnk0+5broI7YzPz\n01nYxQqDr/iJ7JSpJ8leac5d\n-----END PRIVATE KEY-----\n",
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
MYSQL_DATABASE_PASSWORD = "500fpgup1lieay72"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
TICK_TIME_IN_SECONDS = 60
DB_SECRET = "8qgq4c34i51gnm17"
GAME_ROUND = 200
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = '8qgq4c34i51gnm17'
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
      'secret' => ['8qgq4c34i51gnm17']
    }
  }
]
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/config/teamConfig.json << END2
{
    "teams": {"0":{"name":"team1","hashed_password":"h2pkp0gs9338kp1b"},"1":{"name":"team2","hashed_password":"1sx8yjkqz63stmgr"},"2":{"name":"team3","hashed_password":"h5t04gtxpsyzdzeo"},"3":{"name":"team4","hashed_password":"g8u5xgjp48fip42a"},"4":{"name":"team5","hashed_password":"cny3jiqazap2riad"}},
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/gitlab/config.json << END2
{
    "teams": {"0":{"name":"team1","hashed_password":"h2pkp0gs9338kp1b"},"1":{"name":"team2","hashed_password":"1sx8yjkqz63stmgr"},"2":{"name":"team3","hashed_password":"h5t04gtxpsyzdzeo"},"3":{"name":"team4","hashed_password":"g8u5xgjp48fip42a"},"4":{"name":"team5","hashed_password":"cny3jiqazap2riad"}},
    "services": ["poipoi","sillybox","tattletale"]
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
sleep 5
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
