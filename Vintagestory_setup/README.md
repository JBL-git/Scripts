vintage story microsoft.NETCore.App version 8.0.16 works for dedicated server hosting in case anyone was curious. Not all linux operating systems have access to net 7 as easily like aws linux for example. This means when you start your server, it may crash. You need to change the vintagestoryserver.runtimeconfig.json file to what you are using.

After you download create_users.sh and download the setup.sh of your choice, please do the following things before running the scripts.

# do these commands first


sudo visudo

# find this line (# %wheel ALL=(ALL:ALL) ALL)
# uncomment it
# press ctrl+x  then Y and  then ENTER
# now vic and jac can use sudo


# please cd to the directory that holds the scripts and run the following commands
# this makes these files only accessible to root


sudo chown root:root createusers.sh
sudo chown root:root setup.sh

# this makes it to where only root can read write and execute these files. Make sure you change the name of the setup.sh you downloaded
sudo chmod 700 createusers.sh
sudo chmod 700 setup.sh

