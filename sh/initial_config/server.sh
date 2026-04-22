#!/bin/sh

#Delete, if directories already exist
rm -rf ~/windrose_server
rm -rf ~/.windrose_server

#Create directoroes
mkdir -p ~/windrose_server
mkdir -p ~/.windrose_server

# Attempt to download Windrose binaries
MAX_RETRIES=3
RETRY_COUNT=0
until [ "$(ls -A ~/windrose_server 2>/dev/null)" ] && [ "$EXIT_CODE" = "0" ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    echo "Folder is empty or SteamCMD failed."

    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
        echo "Maximum retries reached."
        exit 1
    fi

    echo "Retry count: #$RETRY_COUNT..."
    steamcmd +force_install_dir ~/windrose_server +@sSteamCmdForcePlatformType windows +login anonymous +app_update 4129620 validate +quit
             
    EXIT_CODE=$?
    if [ -z "$(ls -A ~/windrose_server 2>/dev/null)" ] && [ "$EXIT_CODE" != "0" ]; then
        echo "Attempt $RETRY_COUNT failed or folder is empty. Retrying in 5 seconds."
        sleep 5
    fi
done

# Ensure read, write permissions are set
chmod -R u+rwx ~/windrose_server

# Initialise wine
WINEPREFIX=~/.windrose_server WINEARCH=win64 WINEDLLOVERRIDES="mscoree,mshtml=" xvfb-run -a wineboot -u
wineserver -w
# Sometimes vcrun2022 can hang if run immediately. 
# Feel free to remove sleep if you do not have any issues
sleep 5
# If this keeps hanging on you then make sure to nuke the ./windrose_server folder
# Kill all wine processes -> pkill -9 wine
# Restart server
# Rerun the config script again
# If you can't get past this then you have a problem \o/
WINEPREFIX=~/.windrose_server WINEDEBUG=-all xvfb-run -a winetricks -v -q vcrun2022
wineserver -w

# Run the server for the first time in detached session
tmux new -d -s windrose_server "WINEPREFIX=~/.windrose_server xvfb-run -a wine ~/windrose_server/WindroseServer.exe -log -nullrhi"

# tmux attach -t windrose_server <-- To attach and kill it