#!/bin/bash

# List of repositories to sync
REPOS=(
    "$HOME/dotfiles"
    "$HOME/myconfig/settings"
)

LOG_FILE="$HOME/bin/sync_repos.log"

# Perform sync for each repo once
for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Syncing $repo..." >> "$LOG_FILE"
        
        # Change to repo directory
        pushd "$repo" > /dev/null
        
        # Pull latest changes from origin master
        git pull origin master --quiet >> "$LOG_FILE" 2>&1
        
        # Check if there are local changes to push
        if [[ -n $(git status --porcelain) ]]; then
            echo "  Found local changes, committing and pushing..." >> "$LOG_FILE"
            # git add .
            git commit -m "Auto-sync: $(date +'%Y-%m-%d %H:%M:%S')" --quiet
            git push origin master --quiet >> "$LOG_FILE" 2>&1
        else
            # Even if no local changes, try to push in case of unpushed commits
            git push origin master --quiet >> "$LOG_FILE" 2>&1
        fi
        
        popd > /dev/null
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Directory not found: $repo" >> "$LOG_FILE"
    fi
done

# Keep only the last 1000 lines of the log to prevent it from growing too large
if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
