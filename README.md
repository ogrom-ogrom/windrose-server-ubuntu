**Disclaimer: The following scripts and steps have been tested and replicated several times on my Ubuntu 24.04 box. Be warned that I cannot guarantee they will work on yours due to many possible and unforeseen technical issues. After all, no two Linux boxes are identical.**

# Pre-requisite & Assumptions
- Dedicated headless Linux server with an Ubuntu image installed (VPS or physical with AVX2 support).
- Knowledge of the Linux SSH terminal.
- Understanding of how to secure your own server (e.g., blocking port 22, SSH keys), as this will not be covered here.
- An up-to-date Ubuntu installation.
- A sudo-capable user.

Not really a requirement, but it is worth a quick read https://steamcommunity.com/sharedfiles/filedetails/?id=3706337486

# Dependencies
- Wine 11.0
- xvfb
- cabextract
- Winetricks (vcrun2022 d3dcompiler_47)
- steamCMD (Windrose win32 files)

# Configuration
## Enable 32-bit support
We want our server to handle 32-bit software packages.
```ssh
sudo dpkg --add-architecture i386
sudo apt update
```

## Installing Wine
Download the Wine security keys and add the official source list for your specific Ubuntu version.
```ssh
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/$(lsb_release -cs)/winehq-$(lsb_release -cs).sources
sudo apt update
```

Now, install Wine (which should provide the latest version), xvfb, and cabextract.
```ssh
sudo apt install --install-recommends winehq-stable xvfb cabextract -y
```

The next step is to download Winetricks and ensure you have the latest update.

**Note: A self-update is important because, without it (at least on my box), it will download an ancient version.**
```ssh
sudo apt install winetricks -y
yes | sudo winetricks -q --self-update
```

## Installing SteamCMD
This can be found in the multiverse repository; accept the EULAs and install SteamCMD.
```
sudo add-apt-repository multiverse -y
sudo apt update

echo steam steam/question select I AGREE | debconf-set-selections
echo steam steam/license note | debconf-set-selections

sudo apt install steamcmd -y
sudo apt update
```

## Create user for your server
This step is optional, provided you are not using 'root'. If you are, please create a standard user now; running as 'root' is highly discouraged and can lead to significant security and permission issues.
```ssh
useradd -m -s /bin/bash windrose_server && passwd windrose_server
```

Once done, switch.
```ssh
su - windrose_server
```

## Downloading Server Binaries
Create two folders in your home directory.
```ssh
mkdir -p ~/windrose_server
mkdir -p ~/.windrose_server
```

Download the binaries. This often fails on the first attempt but usually works on the second. Classic SteamCMD!
```ssh
steamcmd +force_install_dir ~/windrose_server +@sSteamCmdForcePlatformType windows +login anonymous +app_update 4129620 validate +quit
```

Finally, grant yourself full control of the folder. This resolved all the read/write permission issues I encountered.
```ssh
chmod -R u+rwx ~/windrose_server
```

## Initialise Wine
**Warning**: This is the stage where you are most likely to encounter issues. Most problems typically stem from missing dependencies (which should have been covered in the previous steps) or incorrect directory permissions. Ideally, the process should complete without hanging.

**Note**: It is perfectly normal to see 'fixme' warnings in the terminal output.

```ssh
WINEPREFIX=~/.windrose_server WINEARCH=win64 WINEDLLOVERRIDES="mscoree,mshtml=" xvfb-run -a wineboot -u
```

Install Windows dependencies and restart wineserver for good measure.
```ssh
WINEPREFIX=~/.windrose_server WINEDEBUG=-all xvfb-run -a winetricks -v -q vcrun2022
wineserver -w
```
Sometimes winetricks can hang during the installation of vcrun2022. If that happens, I don't bother investigating, I generally just delete /.windrose_server folder, reboot the box and start over with the Wine. This nuclear turn off/on fixes the hang in most cases. However, keep in mind, this only works when you do not have an actual error otherwise it will keep hanging on forever!

## Running your server
Provided that everything has been successful up to this point, you can now launch the Windrose server! This is the command you will use to start it from now on.

`tmux` is a terminal multiplexer which allows you to create a new detached terminal and run your server process there. 
```ssh
tmux new -d -s windrose_server "WINEPREFIX=~/.windrose_server xvfb-run -a wine ~/windrose_server/WindroseServer.exe -log -nullrhi"
```

To see the detached terminal, you will need to attach. Once you attach it, CTRL + B -> D to detach it.
```ssh
tmux attach -t windrose_server
```

You can quickly check if your server is actually running by checking a separate terminal. If you can see a spawned process with significant memory and CPU usage, then you are sorted.
```ssh
top -c -p $(pgrep -d',' -f WindroseServer)
```

However, before you celebrate too soon, ensure that ServerDescription.json has been generated in the R5 directory. There, you will find your invite code to verify whether your server is actually active.
```ssh
cat windrose_server/R5/ServerDescription.json
```

## Final notes
Do not forget to password-protect your actual Windrose server! 

Additionally, you can now set up a direct IP connection. I can confirm that direct IP addressing is working as expected (for me).

Note for myself: Improve this page ¯\\_(ツ)_/¯
