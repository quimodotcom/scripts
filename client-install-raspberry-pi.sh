#!/bin/bash

# Stream-Pi Client Installer Script for Raspberry Pi 
# This Script heavily makes use of a lot of code from the official raspi-config script (https://github.com/RPi-Distro/raspi-config)

VERSION=1.0.0
CONFIG=/boot/config.txt
NINENINERULES=/etc/udev/rules.d/99-com.rules
INSTALL_DIRECTORY=~/
FOLDER_NAME=stream-pi-client/
GPU_MEM=128


# Necessary Methods

is_pi() {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] || [ "$ARCH" = "arm64" ] ; then
    return 0
  else
    return 1
  fi
}


# Check whether this is even a pi or not

if ! is_pi ; then
   echo This is not a Pi. This script is only for Raspberry Pi Devices.
   exit 1
fi


echo Stream-Pi Client Installer Script For Raspberry Pi
echo Version "$VERSION"


# Install required dependencies ...

echo Installing required dependencies ...

if ! sudo apt -y update ; then
   echo Unable to run apt update. Check internet connection / permissions. Quitting ...
   exit 1
fi

if ! sudo apt -y install unzip axel libegl-mesa0 libegl1 libgbm1 libgles2 libpango-1.0.0 libpangoft2-1.0.0 libgl1-mesa-dri gldriver-test ; then
   echo Unable to install required dependencies. Quitting ...
   exit 1
fi



# Finally Download and extract

echo Downloading Client ...

cd "$INSTALL_DIRECTORY"
if ! axel -a -n 4 --output=spi.zip https://github.com/stream-pi/client/releases/download/1.0.0/client-linux-arm7-1.0.0-EA+2.zip ; then
   echo Unable to Download. Quitting ...
   exit 1
fi

echo Previous Clean up ...
rm -rf "$FOLDER_NAME"



echo Extracting ...


unzip spi.zip -d "$FOLDER_NAME"

echo Clean up ...
rm -rf spi.zip

echo Setting permissions ...
cd "$FOLDER_NAME"
chmod +x run_console
chmod +x run_desktop
chmod +x jre/bin/java


# Add support for touch 

echo Adding touch support ...

# Check if already exists 


if grep -q -E "chown -R root:input /sys/class/input/\*/ && chmod -R 770 /sys/class/input/\*/;" /etc/udev/rules.d/99-com.rules ; then
echo Touch support already exists ...
else
sudo tee -a "$NINENINERULES" > /dev/null <<EOT
SUBSYSTEM=="input*", PROGRAM="/bin/sh -c '\
chown -R root:input /sys/class/input/*/ && chmod -R 770 /sys/class/input/*/;\
'"
EOT
fi


# Turn on FAKE KMS Driver

echo Turning ON FAKE KMS Driver ...

if ! grep -q "dtoverlay=vc4-fkms-v3d" ; then
   sudo printf "dtoverlay=vc4-fkms-v3d\n" >> "$CONFIG"
fi


# Add GPU MEM

if ! grep -q "gpu_mem=$(GPU_MEM)" ; then
   sudo printf "gpu_mem=$(GPU_MEM)\n" >> "$CONFIG"
fi


echo Stream-Pi Client is installed. However your Pi needs to be restarted
echo After Restart, You may cd to "$INSTALL_DIRECTORY""$FOLDER_NAME"
echo and run './run_console' or './run_desktop'
echo Restarting in 5 seconds ...
sleep 5

sudo reboot

