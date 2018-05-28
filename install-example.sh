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
  config.vm.network "forwarded_port", guest: 14567, host: 14567 # Docker Registry
  config.vm.network "forwarded_port", guest: 15001, host: 15001 # Gitlab
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
    "teams": [{"name":"team1","namespace":"team1"},{"name":"team2","namespace":"team2"}],
    "flag_storage_folder": "/flags",
    "containers_host": "localhost",
    "containers_ports_start" : 10000,
    "round" : 20
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "awesome-ctf-4d303",
  "private_key_id": "a9c3bd0ac301abb9706e5821eb83b991f489e671",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCmolmFPefo8Bf6\nPsU3tPVgjUdWoOkYAZQm2HMo+X4WMpVFmNxkOnKYav6bvV1C0zznpzQwW61BCd1W\np0uFrDaNDpFAh/ehB4Yui0XB6VLacmTfpVGcfxphNKe5JbnHcFQCPtiQN8b9mtsq\nHwV0xaQcCxaHLXFa+6owjTD+np+V4ggS/jo8Dh6wG04HP2eoIj8VP7V8mKCXOkT/\nOB9Ry1Zp4yKepXSN1tKGiZr08welHEu5iiMbjHibRjYWJbyqe7IaeEJfPc2Rsvv7\nxzmN8i3NyAQqiA5JrxMbNfm7MIEqbIT3RALZgZZq7OkRZ2i7Dsv4VDbbAtWLI49C\nhD8YaC7VAgMBAAECggEAATB18ptBQTqbdTQG/NGMEcsYWAAwgbUbLVbMpZ14PqjQ\nQ22mnwmCwV88H3jvxjcTP3UETJcO6sCrBYAOrC7ROdsBguQlio7u8HyafBqR9pCr\n8yOvLC6FDe4OB2aDR67fzp9LtOXNBAjbqRaNF6sEc5XJrJ/QqA1VRuDvGVYg/fUa\n1N7ZAwX910QAPwGJOm4KBxgdO8JicKbeb5fjZ0q+I+K3Oibve+XN9eelKeqvu+6A\nSZfIuGocGXj4/9TLwmnkg5MmWaP4ldBEA1hsXo0V4AhjH1A0dsIX9CqZ7v9P4mwF\nO0C3Uw6pfuDqlvJUtwhh1UPLWvwutmwV88d0tPOrSQKBgQDcFPV4YM4hg1vTGwp7\ny7IcMY9TBnW/arFtjiJvCzBsixcI35cFVUF/iGph9TDI8Uum4H6fu79Ut8GR1oAR\nFA0BvtgichxhXJwbN2tzwPvmyy6nfzvYRpcYizl0ilaBFonVQTCaBWPPg6xYhxAc\nN56xRtdcG1gdP9F+TOPaVl5uaQKBgQDB1Fdb/gBwg7fyxxwHG6RKONp7+u3RsVwN\nPBe+IiEtHjno1dEy+PBA9DZyBXNZ3bEN4M4LRROY91F7/hVFIK3xGBS9qekQYPR+\nMStbF0hpsvXFXhYDaC0SF0bC+1r0UchU+7+hUxj1idlHafT4Tb/PW+b3Di8O++97\n5Njo+0yHjQKBgQCzqrCSq4TcOx61grfWRH6NIbB9+SIbOIDMjWJzANFxa0NMzSu/\nANDNypH+kmpXQRWfkFoPEPirsq/l3RUD3DiaGjDcPggJO899MIsaHowG6AyYVPiI\nIWiscsxe5ailDb9MR0HkG05WVIpYYzq1rnpxAwJBgVk316ew0hiZYDULMQKBgG62\nlTesfB/IfPell3LP7SWgF9wdVl4iSowcuQsXf4+/5iACkb3lx4WyeK7kQiEgqhNd\nRxPU3v7OtbJ3TTrxEanWsXIsbT23w6+Y8kTTpb8KQ6v6s+Q6SxQ8S2TwIeHQHPe9\n3JWPW4BUvtE1yoFSF6+ftOuFJIgQi5he/S8G6425AoGBAIvp3jgL25xM9gcWJ1DH\nCYLIDgcOuaRVVlyypAKV8WMiIO4OuJYv/i9Y9spjDJElRXCBzVeoIrPrK+bUUw5i\nHCJcKgMb8SU4dozGEpeh7P4FqhYNKJyeQomyvVL+2LRLK2xipYhlsLoKjU4taB8I\ntVE3AXSZkrpPplcHY54IXUEw\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-npex7@awesome-ctf-4d303.iam.gserviceaccount.com",
  "client_id": "114657258742058353270",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-npex7%40awesome-ctf-4d303.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/teamConfig.json << END2
{
    "api_secret": "2k86i9tdq4wiqkud",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"fqz32m587srwizna"},"1":{"name":"team2","hashed_password":"j8yim9wkxk3yyii0"}}
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/static/js/firebase.init.js << END2
// Initialize Firebase
var config =  {
    apiKey: "AIzaSyDzRQnI4873HM2yWdCnS1bshUuMV26gnPg",
    authDomain: "awesome-ctf-4d303.firebaseapp.com",
    databaseURL: "https://awesome-ctf-4d303.firebaseio.com",
    projectId: "awesome-ctf-4d303",
    storageBucket: "",
    messagingSenderId: "896283687181"
  };
firebase.initializeApp(config);
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "awesome-ctf-4d303",
  "private_key_id": "a9c3bd0ac301abb9706e5821eb83b991f489e671",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCmolmFPefo8Bf6\nPsU3tPVgjUdWoOkYAZQm2HMo+X4WMpVFmNxkOnKYav6bvV1C0zznpzQwW61BCd1W\np0uFrDaNDpFAh/ehB4Yui0XB6VLacmTfpVGcfxphNKe5JbnHcFQCPtiQN8b9mtsq\nHwV0xaQcCxaHLXFa+6owjTD+np+V4ggS/jo8Dh6wG04HP2eoIj8VP7V8mKCXOkT/\nOB9Ry1Zp4yKepXSN1tKGiZr08welHEu5iiMbjHibRjYWJbyqe7IaeEJfPc2Rsvv7\nxzmN8i3NyAQqiA5JrxMbNfm7MIEqbIT3RALZgZZq7OkRZ2i7Dsv4VDbbAtWLI49C\nhD8YaC7VAgMBAAECggEAATB18ptBQTqbdTQG/NGMEcsYWAAwgbUbLVbMpZ14PqjQ\nQ22mnwmCwV88H3jvxjcTP3UETJcO6sCrBYAOrC7ROdsBguQlio7u8HyafBqR9pCr\n8yOvLC6FDe4OB2aDR67fzp9LtOXNBAjbqRaNF6sEc5XJrJ/QqA1VRuDvGVYg/fUa\n1N7ZAwX910QAPwGJOm4KBxgdO8JicKbeb5fjZ0q+I+K3Oibve+XN9eelKeqvu+6A\nSZfIuGocGXj4/9TLwmnkg5MmWaP4ldBEA1hsXo0V4AhjH1A0dsIX9CqZ7v9P4mwF\nO0C3Uw6pfuDqlvJUtwhh1UPLWvwutmwV88d0tPOrSQKBgQDcFPV4YM4hg1vTGwp7\ny7IcMY9TBnW/arFtjiJvCzBsixcI35cFVUF/iGph9TDI8Uum4H6fu79Ut8GR1oAR\nFA0BvtgichxhXJwbN2tzwPvmyy6nfzvYRpcYizl0ilaBFonVQTCaBWPPg6xYhxAc\nN56xRtdcG1gdP9F+TOPaVl5uaQKBgQDB1Fdb/gBwg7fyxxwHG6RKONp7+u3RsVwN\nPBe+IiEtHjno1dEy+PBA9DZyBXNZ3bEN4M4LRROY91F7/hVFIK3xGBS9qekQYPR+\nMStbF0hpsvXFXhYDaC0SF0bC+1r0UchU+7+hUxj1idlHafT4Tb/PW+b3Di8O++97\n5Njo+0yHjQKBgQCzqrCSq4TcOx61grfWRH6NIbB9+SIbOIDMjWJzANFxa0NMzSu/\nANDNypH+kmpXQRWfkFoPEPirsq/l3RUD3DiaGjDcPggJO899MIsaHowG6AyYVPiI\nIWiscsxe5ailDb9MR0HkG05WVIpYYzq1rnpxAwJBgVk316ew0hiZYDULMQKBgG62\nlTesfB/IfPell3LP7SWgF9wdVl4iSowcuQsXf4+/5iACkb3lx4WyeK7kQiEgqhNd\nRxPU3v7OtbJ3TTrxEanWsXIsbT23w6+Y8kTTpb8KQ6v6s+Q6SxQ8S2TwIeHQHPe9\n3JWPW4BUvtE1yoFSF6+ftOuFJIgQi5he/S8G6425AoGBAIvp3jgL25xM9gcWJ1DH\nCYLIDgcOuaRVVlyypAKV8WMiIO4OuJYv/i9Y9spjDJElRXCBzVeoIrPrK+bUUw5i\nHCJcKgMb8SU4dozGEpeh7P4FqhYNKJyeQomyvVL+2LRLK2xipYhlsLoKjU4taB8I\ntVE3AXSZkrpPplcHY54IXUEw\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-npex7@awesome-ctf-4d303.iam.gserviceaccount.com",
  "client_id": "114657258742058353270",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-npex7%40awesome-ctf-4d303.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/database/settings.py << END2
DEBUG = True
MYSQL_DATABASE_USER = "root"
MYSQL_DATABASE_INIT_PASSWORD = "http8804"
MYSQL_DATABASE_PASSWORD = "1npzse91uiyc1guo"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
TICK_TIME_IN_SECONDS = 600
DB_SECRET = "2k86i9tdq4wiqkud"
GAME_ROUND = 20
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = '2k86i9tdq4wiqkud'
END2
sudo tee /etc/gitlab/gitlab.rb << END2
external_url 'https://awesome-ctf.tk:15001'
registry_external_url 'https://awesome-ctf.tk:14567'
registry['notifications'] = [
  {
    'name' => 'Gameserver',
    'url' => 'http://localhost:4000/container_changed',
    'timeout' => '1s',
    'threshold' => 5,
    'backoff' => '2s',
    'headers' => {
      'secret' => ['2k86i9tdq4wiqkud']
    }
  }
]
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/config/teamConfig.json << END2
{
    "teams": {"0":{"name":"team1","hashed_password":"fqz32m587srwizna"},"1":{"name":"team2","hashed_password":"j8yim9wkxk3yyii0"}}
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/gitlab/config.json << END2
{
    "teams": {"0":{"name":"team1","hashed_password":"fqz32m587srwizna"},"1":{"name":"team2","hashed_password":"j8yim9wkxk3yyii0"}},
    "services": ["poipoi","sillybox","tattletale"]
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/gitlab/csr_config.json << END2
[ req ]
distinguished_name="req_distinguished_name"
prompt="no"

[ req_distinguished_name ]
C="KR"
ST="Daejeon"
L="KAIST"
O="Awesome-CTF"
CN="awesome-ctf.tk"
END2

cd \$VAGRANT_HOME/HTTP-CTF/container-creator
sudo python create_containers.py -sl ../services -c example.json
sudo python create_flag_dirs.py -c example.json

cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/Awesome-CTF/initial_db_state.json

cd \$VAGRANT_HOME/HTTP-CTF/gitlab
sudo mkdir -p /etc/gitlab/ssl
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/gitlab/ssl/awesome-ctf.tk.key -out /etc/gitlab/ssl/awesome-ctf.tk.crt -days 365 -nodes -config csr_config.json
sudo gitlab-ctl reconfigure
sudo gitlab-rails console production < gitlab-temp-passwd.sh
sleep 5
sudo python initialize.py -c config.json

cd \$VAGRANT_HOME/HTTP-CTF/container-creator
sudo docker run -d -p 5000:5000 --restart=always --name docker-registry \
  -v /etc/gitlab/ssl:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/awesome-ctf.tk.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/awesome-ctf.tk.key \
  registry
sudo service docker restart
sudo docker login --username=root --password=temp_passwd localhost:5000
sudo python push_containers.py -sl ../services -c example.json -ds localhost -dpo 5000 -du root -dpass temp_passwd

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

