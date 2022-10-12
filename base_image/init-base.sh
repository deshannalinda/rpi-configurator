#!/usr/bin/env bash

set -e
set -u

# Set colors to format output
NORMAL="\e[0m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[36m"
MAGENTA="\e[35m"

INFO="${GREEN}[INFO]${NORMAL} "
ERROR="${RED}[ERROR]${NORMAL} "

# See what I can do
if [ $(id | grep 'uid=0(root)' | wc -l) -ne "1" ]
then
    echo -e "${ERROR}You are not root "
    exit
fi

# Set temp mount location
temp_base="/tmp/raspios"
boot_mount="${temp_base}/boot"
root_mount="${temp_base}/root"
mkdir -pv ${boot_mount}
mkdir -pv ${root_mount}

# Set download location
downloads="downloads"
mkdir -pv ${downloads}

url_base="https://downloads.raspberrypi.org/raspios_armhf/images/"
version="$( wget -q ${url_base} -O - | awk -F '"' '/raspios/ {print $8}' - | sort -nr | head -1 )"
sha_file=$( wget -q ${url_base}/${version} -O - | awk -F '"' '/raspios.*sha256/ {print $8}' - )
sha_sum=$( wget -q "${url_base}/${version}/${sha_file}" -O - | awk '{print $1}' )

# Download the latest image, using the  --continue "Continue getting a partially-downloaded file"
image_file="${downloads}/"
image_file=${sha_file%.sha256}
image_url=${url_base}/${version}/${image_file}
download_path=${downloads}/${image_file}
wget --continue --show-progress ${image_url} -O ${download_path}

echo -e "${INFO}Checking the SHA-256 of the downloaded image matches \"${sha_sum}\""

if [ $( sha256sum ${download_path} | grep ${sha_sum} | wc -l ) -eq "1" ]
then
    echo -e "${INFO}The SHA-256 matches"
else
    echo -e "${ERROR}The SHA-256 did not match"
    exit 5
fi

# unzip
extracted_image="${downloads}/"$( 7z l ${download_path} | awk '/raspios.*img$/ {print $NF}' )
echo -e "${INFO}The name of the image is \"${extracted_image}\""

7z x -o${downloads} ${download_path}

if [ ! -e ${extracted_image} ]
then
    echo -e "${ERROR}Can't find the image \"${extracted_image}\""
    exit 6
fi

loop_base=$( losetup --find --show --partscan "${extracted_image}" )
lsblk ${loop_base}

echo -e "${INFO}Mounting the boot disk to: ${boot_mount}"
mount ${loop_base}p1 "${boot_mount}"

echo -e "${INFO}Mounting the root disk to: ${root_mount}"
mount -v ${loop_base}p2 "${root_mount}"

# Enabling SSH
echo -e "${INFO}Enabling SSH"
touch "${boot_mount}/ssh"

# Creating a new user & password
echo -e "${INFO}New user wizard"
read -p "Enter a new username [pi]: " username
username=${username:-pi}
read -sp "Enter a new password [raspberry]: " password
password=${password:-raspberry}
encrypted_password=$( echo ${password} | openssl passwd -6 -stdin )
echo "${username}:${encrypted_password}" > ${boot_mount}/userconf

echo -e "${INFO}Unmounting..."
umount ${boot_mount}
umount ${root_mount}

new_name="${extracted_image%.*}-ssh-enabled.img"
cp -v "${extracted_image}" "${new_name}"

losetup --detach ${loop_base}
lsblk

echo -e "${MAGENTA}"
echo -e "Now you can burn the disk using something like:"
echo -e "      dd bs=4M status=progress if=${new_name} of=/dev/disk2"
echo -e "${NORMAL}"
