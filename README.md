# How to start
> You need a file named `install.sh` and a directory named `services` to configure.
```
# Download install.sh
$ git clone https://github.com/KAIST-CS408E/HTTP-CTF-configuration.git && cd HTTP-CTF-configuration

# Download services
$ git clone https://github.com/inctf/inctf-framework.git
$ mv inctf-framework/services .
$ rm -rf inctf-framework

# Configure
$ sh install.sh
```

# [Downloading vagrant box is extremely slow...](https://github.com/hashicorp/vagrant/issues/5319)
> Before Configure
1. You can download `package.box` in [here](https://drive.google.com/open?id=15ilWF6dkjt6v13dCsFX5Em5jIQ2CrUhC)
2. Move the `package.box` file to the project root directory
3. Uncomment `vagrant box add hobin/create-ctf-competition-template ./package.box` in `install.sh` line 4
4. `$ sh install.sh`
