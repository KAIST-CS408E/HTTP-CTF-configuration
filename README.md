# Usage

## Step 1: Install Vagrant
> We will use Vagrant to easily configure your CTF and isolate the gaming environment from your machine.

Go to https://www.vagrantup.com/downloads.html and install Vagrant using proper package for your OS and architecture.


## Step 2: Download vagrant box
> We created a vagrant box that all the necessary tools are installed. Let's download it and start from here.

```
$ vagrant box add hobin/create-ctf-competition-template
```

* **NOTE: [Downloading vagrant box is extremely slow...](https://github.com/hashicorp/vagrant/issues/5319)**

    You can download `package.box` in [here](https://drive.google.com/open?id=15ilWF6dkjt6v13dCsFX5Em5jIQ2CrUhC), and
    ```
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
