# Raspberry Pi Configurator

Here,  we'll discuss how to create a new custom image from the latest Raspbian OS and copy it into a SD card.

## Creating Base Image

### STEP 1
Spin-up & SSH into the Vagrant box if you are not using Linux.
```shell
vagrant up && vagrant ssh
cd base_image
```

### STEP 2
Run the script with `sudo`.
```shell
sudo ./init-base.sh
```

This will perform the following
1. Creates a `downloads`
2. Download the latest `raspios_armhf` image
3. Enable SSH on image 
4. Create new username & password for the default user 
5. Generate the new 'custom' image - `xxx-armf-ssh-enabled.img`

## Copy (`dd`) it into the SD card. 

1. Exit from vagrant SSH.
2. Insert the SD card.
3. Run the following command to unmount it. 
```shell
diskutil unmountDisk /dev/disk2
```
4. Copy generated image to SD card - something similar to this.
```shell
sudo dd bs=4M status=progress if=base_image/downloads/2022-09-22-raspios-bullseye-armhf-ssh-enabled.img of=/dev/disk2
```
