#!/bin/bash

# List of repositories to sync
REPOS=(
    "$HOME/dotfiles"
    "$HOME/myconfig/settings"
    "c:/Users/sampa/projects/my_notes"
)

LOG_FILE="$HOME/bin/sync_repos.log"

# Perform sync for each repo once
for repo in "${REPOS[@]}"; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Checking repo: $repo" >> "$LOG_FILE"
    if [ -d "$repo" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Syncing $repo..." >> "$LOG_FILE"
        
        # Change to repo directory
        pushd "$repo" > /dev/null
        
        # Check if there are local changes to tracked files
        if [[ -n $(git status --porcelain | grep -v '??') ]]; then
            echo "  Found changes in tracked files, committing before pull..." >> "$LOG_FILE"
            # Only add tracked files that have been modified or deleted
            git add -u
            git commit -m "Auto-sync from $USER@$(hostname)" --quiet
        fi

        # Pull latest changes from origin master
        git pull origin master --quiet >> "$LOG_FILE" 2>&1

        # Push any local commits
        git push origin master --quiet >> "$LOG_FILE" 2>&1
        
        popd > /dev/null
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Directory not found: $repo" >> "$LOG_FILE"
    fi
done

# Keep only the last 1000 lines of the log to prevent it from growing too large
if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
