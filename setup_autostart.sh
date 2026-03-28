#!/bin/bash

# Path to the sync script
SYNC_SCRIPT="$HOME/bin/sync_repos.sh"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Detected Windows (Git Bash)..."
    # Use $HOME to get the user profile path correctly in Git Bash
    STARTUP_DIR="$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
    VBS_LAUNCHER="$STARTUP_DIR/start_sync_hidden.vbs"
    
    echo "Creating VBS launcher in Startup folder..."
    cat > "$VBS_LAUNCHER" << EOF
Set WshShell = CreateObject("WScript.Shell")
' Run bash hidden
WshShell.Run "bash.exe -c \"$SYNC_SCRIPT\"", 0, False
EOF
    echo "Done! Sync script will run hidden on next login."

else
    echo "Detected Linux/Unix..."
    AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    
    cat > "$AUTOSTART_DIR/sync_repos.desktop" << EOF
[Desktop Entry]
Type=Application
Exec=$SYNC_SCRIPT
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Repo Sync Service
Comment=Syncs git repos every 2 minutes
EOF
    chmod +x "$SYNC_SCRIPT"
    echo "Done! Desktop entry created in $AUTOSTART_DIR"
fi
