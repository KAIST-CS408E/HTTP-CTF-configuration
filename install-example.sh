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
    "num_services": 3,
    "name": "CTF-example",
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
  "project_id": "cs408e-http",
  "private_key_id": "fcec7bee57a5b4aeabf611a44ff0093e8639c09f",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC+dGjY03RU62c0\n8OR2+9t7x7R+8If1D3GCjyrIZRgvMAKId0e2/8dTblP6TIBO0liCiiuWJKc2l143\nd8BH5VOHVWeefdkqQpyd+1H/VyBsEVCQNEFH+ZUkaARqzk+qsuUx0pVmSotblQcF\n4N+dEaad3aRIS8OREraE7BzafxbuCUHDSo0XDmW1nGExQ+oXswTcMix5H+GbeDTw\nRxrzDocqHhNs5qI7EtC8X2nUHp74D6EiNJ5c35r+fAcXzUFvY/HyXk8xxsMgHGyD\nVsVLJX+aqbTGe79Q/161atXlKuAyyfyBTia1wkRbRtchTRGw/YUkhfJ9t9ohW/Rk\nNUhFFxavAgMBAAECggEAERcPZ3wwtq65qqRTzqIoCPybzj5APPXJ+O4RkpI7xX7j\nOKKszUI40obrwzdFK42FgrqU/FqapJ6YRkBD1qUV8JFx2bovmAgKghn7ZX8dz4S4\nPCXBloynXPEhNa0AtMUWevjguMvx+GGwPnn2JuPewHtokqeLINlTMSyiJDB+UBVd\n3n8s8mZ6jOwr6w/kbloo5qCKv25zFP0lW562u9FzNBAQa8pONfOEYmZJ4kLKKk3s\nC5FOZwMBLCizT/GIpDVKXh1vrjwoiCmuHF0SUZIYre6oBizGY4pKvjc0SGLhRk6a\nlN+rn3GpR+AkplI27G+MynS1TbQYujM0B2f1I0LXxQKBgQDqK0/oBxuWuzE222LE\nfKIWi+zRAJ35/tIFB0zAjSLnifJTOJipJEJSEQ/AJLpdcKMNk5pmhEUSHrgjd1uX\nB1t/JTaZkO9JYxNGO7fKMeHcfX3KajFFo8/h8r11bEjYCpuV7lAbqtqeaINfWsen\njcjKa1//280hqe2maUna3ZNybQKBgQDQNc6SZC9GioMKvHKFEP0C+J2x5Vsh37iM\nq7vOGlAqTvOjxS5kG1TuZyuFAgVYuEUHDZqiDGrJkaOvPsCIh05QEyeWeWbzPe4G\nYHC+JDkoMeoA+Z8gVFSSJgK2cUW7sYU2zo+nweIjlcqXZS07PZZJnUJeoU311wVx\nQA4a9+pcCwKBgBBErAt5mvAQ1y1xdl4iLnyUggJPIaqBioOw6yMhawBc9AnWD70I\neNcMumRl6NCfB6Tk0UA4BjhpC+/i1ekbKL8fjbiDeixGBsvFUFJqvr87tKaAVCX7\naHDRFVp4CGOB8ScsZEJXz1Jb/mx8eQxp7D4r0YKL+adSD+GUxP3AkQLNAoGAGLKp\nRFg5+2Ym0Tk1ZG91c8rF+fo46zW8kIM2jeY1KC+hWwXi0OElG/qFAQwSUknZdlK4\nywwqBqsN/ZW2BPv34CvFgGX6PlRUTdFWzldBqHDzTxZNN+qI9aUooTeii/cs1CmA\nhOfMyWfVVkwcJ3DQyP6shskflE/jR2HPyocp960CgYEA3sAUO2u7y8PqiWXshBzg\nBylTxKWFLWVn7gqJPWNXUVR2x0VAuH+nFNX4tLCrpyeNOhziS+vt2fIpvoX0u0ld\n58+CVZMIMAlRdn1gnGzTXa3PAfafW9jBWP+eoIrDH6/sE0+KF+9nUQNtaYaRfifD\nnbbfjkJipOTxXy9/kBfVJdQ=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-8cfa6@cs408e-http.iam.gserviceaccount.com",
  "client_id": "113214710667042764687",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-8cfa6%40cs408e-http.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/config/teamConfig.json << END2
{
    "api_secret": "kkosraclkkd4kb2g",
    "name": "CS408(E)_HTTP_CTF",
    "api_base_url": "http://127.0.0.1:4000",
    "teams": {"0":{"name":"team1","hashed_password":"hgltzitmee7kg281"},"1":{"name":"team2","hashed_password":"39msu1bd6j290hmu"},"2":{"name":"team3","hashed_password":"ourac0z55zprxo0k"},"3":{"name":"team4","hashed_password":"c6p9czzn4iyzkxr3"},"4":{"name":"team5","hashed_password":"cq6rclb7ukh60l4q"}}
}
END2

tee \$VAGRANT_HOME/HTTP-CTF/dashboard/static/js/firebase.init.js << END2
// Initialize Firebase
var config = {
    apiKey: "AIzaSyAEa3nRkUUT5Q4qoiLF5fuClkKYqDL8l1Q",
    authDomain: "cs408e-http.firebaseapp.com",
    databaseURL: "https://cs408e-http.firebaseio.com",
    projectId: "cs408e-http",
    storageBucket: "cs408e-http.appspot.com",
    messagingSenderId: "67045887531"
  };
firebase.initializeApp(config);
END2

tee \$VAGRANT_HOME/HTTP-CTF/database/config/firebaseConfig.json << END2
{
  "type": "service_account",
  "project_id": "cs408e-http",
  "private_key_id": "fcec7bee57a5b4aeabf611a44ff0093e8639c09f",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC+dGjY03RU62c0\n8OR2+9t7x7R+8If1D3GCjyrIZRgvMAKId0e2/8dTblP6TIBO0liCiiuWJKc2l143\nd8BH5VOHVWeefdkqQpyd+1H/VyBsEVCQNEFH+ZUkaARqzk+qsuUx0pVmSotblQcF\n4N+dEaad3aRIS8OREraE7BzafxbuCUHDSo0XDmW1nGExQ+oXswTcMix5H+GbeDTw\nRxrzDocqHhNs5qI7EtC8X2nUHp74D6EiNJ5c35r+fAcXzUFvY/HyXk8xxsMgHGyD\nVsVLJX+aqbTGe79Q/161atXlKuAyyfyBTia1wkRbRtchTRGw/YUkhfJ9t9ohW/Rk\nNUhFFxavAgMBAAECggEAERcPZ3wwtq65qqRTzqIoCPybzj5APPXJ+O4RkpI7xX7j\nOKKszUI40obrwzdFK42FgrqU/FqapJ6YRkBD1qUV8JFx2bovmAgKghn7ZX8dz4S4\nPCXBloynXPEhNa0AtMUWevjguMvx+GGwPnn2JuPewHtokqeLINlTMSyiJDB+UBVd\n3n8s8mZ6jOwr6w/kbloo5qCKv25zFP0lW562u9FzNBAQa8pONfOEYmZJ4kLKKk3s\nC5FOZwMBLCizT/GIpDVKXh1vrjwoiCmuHF0SUZIYre6oBizGY4pKvjc0SGLhRk6a\nlN+rn3GpR+AkplI27G+MynS1TbQYujM0B2f1I0LXxQKBgQDqK0/oBxuWuzE222LE\nfKIWi+zRAJ35/tIFB0zAjSLnifJTOJipJEJSEQ/AJLpdcKMNk5pmhEUSHrgjd1uX\nB1t/JTaZkO9JYxNGO7fKMeHcfX3KajFFo8/h8r11bEjYCpuV7lAbqtqeaINfWsen\njcjKa1//280hqe2maUna3ZNybQKBgQDQNc6SZC9GioMKvHKFEP0C+J2x5Vsh37iM\nq7vOGlAqTvOjxS5kG1TuZyuFAgVYuEUHDZqiDGrJkaOvPsCIh05QEyeWeWbzPe4G\nYHC+JDkoMeoA+Z8gVFSSJgK2cUW7sYU2zo+nweIjlcqXZS07PZZJnUJeoU311wVx\nQA4a9+pcCwKBgBBErAt5mvAQ1y1xdl4iLnyUggJPIaqBioOw6yMhawBc9AnWD70I\neNcMumRl6NCfB6Tk0UA4BjhpC+/i1ekbKL8fjbiDeixGBsvFUFJqvr87tKaAVCX7\naHDRFVp4CGOB8ScsZEJXz1Jb/mx8eQxp7D4r0YKL+adSD+GUxP3AkQLNAoGAGLKp\nRFg5+2Ym0Tk1ZG91c8rF+fo46zW8kIM2jeY1KC+hWwXi0OElG/qFAQwSUknZdlK4\nywwqBqsN/ZW2BPv34CvFgGX6PlRUTdFWzldBqHDzTxZNN+qI9aUooTeii/cs1CmA\nhOfMyWfVVkwcJ3DQyP6shskflE/jR2HPyocp960CgYEA3sAUO2u7y8PqiWXshBzg\nBylTxKWFLWVn7gqJPWNXUVR2x0VAuH+nFNX4tLCrpyeNOhziS+vt2fIpvoX0u0ld\n58+CVZMIMAlRdn1gnGzTXa3PAfafW9jBWP+eoIrDH6/sE0+KF+9nUQNtaYaRfifD\nnbbfjkJipOTxXy9/kBfVJdQ=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-8cfa6@cs408e-http.iam.gserviceaccount.com",
  "client_id": "113214710667042764687",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-8cfa6%40cs408e-http.iam.gserviceaccount.com"
}

END2

tee \$VAGRANT_HOME/HTTP-CTF/database/settings.py << END2
DEBUG = True
MYSQL_DATABASE_USER = "root"
MYSQL_DATABASE_INIT_PASSWORD = "http8804"
MYSQL_DATABASE_PASSWORD = "ksj7b45fzh1ntws4"
MYSQL_DATABASE_DB = "ctf"
DOCKER_DISTRIBUTION_SERVER = "localhost:5000"
DOCKER_DISTRIBUTION_USER = "root"
DOCKER_DISTRIBUTION_PASS = "http8804"
DOCKER_DISTRIBUTION_EMAIL = "hobincar@kaist.ac.kr"
REMOTE_DOCKER_DAEMON_PORT = 2375
TICK_TIME_IN_SECONDS = 600
DB_SECRET = "kkosraclkkd4kb2g"
END2

tee \$VAGRANT_HOME/HTTP-CTF/scorebot/settings.py << END2
DB_HOST = '127.0.0.1:4000'
DB_SECRET = 'kkosraclkkd4kb2g'
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
      'secret' => ['kkosraclkkd4kb2g']
    }
  }
]
END2

cd \$VAGRANT_HOME/HTTP-CTF/container-creator/
sudo python create_containers.py -sl ../services -c example.json
sudo python create_flag_dirs.py -c example.json

cd \$VAGRANT_HOME/HTTP-CTF/database
sudo python reset_db.py ../container-creator/output/CTF-example/initial_db_state.json
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
