#!/bin/sh

# Support 32-bit software 
sudo dpkg --add-architecture i386
sudo apt update

#Get key for the latest Wine release
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/$(lsb_release -cs)/winehq-$(lsb_release -cs).sources
sudo apt update

# Install Wine 11.0, xvfb and cabextract
sudo apt install --install-recommends winehq-stable xvfb cabextract -y

# Install Winetricks and update to the latest version
sudo apt install winetricks -y
yes | sudo winetricks -q --self-update

# Install SteamCMD
sudo add-apt-repository multiverse -y
sudo apt update

echo steam steam/question select I AGREE | debconf-set-selections
echo steam steam/license note | debconf-set-selections

sudo apt install steamcmd -y
sudo apt update

# Add windrose_server user <-- this prompts for password
sudo useradd -m -s /bin/bash windrose_server
sudo passwd windrose_server
su - windrose_server