# Usage

## Step 1: Install Vagrant
> We will use Vagrant to easily configure your CTF and isolate the gaming environment from your machine.

Go to https://www.vagrantup.com/downloads.html and install Vagrant using proper package for your OS and architecture.


## Step 2: Download vagrant box
> We created a vagrant box that all the necessary tools are installed. Let's download it and start from here.

```
$ wget https://raw.githubusercontent.com/KAIST-CS408E/HTTP-CTF-configuration/master/gdown.pl\?token\=AQ4fCFft6ua68UHeVrSwGmaP2TYiGoQKks5bBnpEwA%3D%3D -O gdown.pl
$ ./gdown.pl https://drive.google.com/file/d/1D2w5nSmDH2xcvAJ8xWbBoA4tuK9WgiXc/view package.box
$ vagrant box add hobin/create-ctf-competition-template ./package.box
```


## Step 3: Prepare services
There should be a `services` directory to provide services for each team. You can see some example services at `services` directory in the root of this repository. You can use it without any modification. Or if you want to write your own services see [here](https://github.com/KAIST-CS408E/HTTP-CTF/blob/master/docs/writing-services.md).

## Step 4: Customize your own CTF
Go to https://cs408e-http.firebaseapp.com and get a shell file named `install.sh`. Remember to use the name of services you prepared in Step 3 when configuring services.


## Step 5: Run your CTF!
Now you should see an `install.sh` file and a `services` directory in your current directory. The only thing left is executing the shell file.

```
$ sh install.sh
```

After a few minutes, the configuration is done and you can go to localhost:18000 to see your CTF homepage
