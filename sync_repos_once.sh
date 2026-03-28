#!/bin/bash

# List of repositories to sync
REPOS=(
    "$HOME/dotfiles"
    "$HOME/myconfig/settings"
)

LOG_FILE="$HOME/bin/sync_repos.log"

for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Syncing $repo..." >> "$LOG_FILE"
        pushd "$repo" > /dev/null
        git pull --rebase --quiet >> "$LOG_FILE" 2>&1
        if [[ -n $(git status --porcelain) ]]; then
            git add .
            git commit -m "Auto-sync: $(date +'%Y-%m-%d %H:%M:%S')" --quiet
            git push --quiet >> "$LOG_FILE" 2>&1
        else
            git push --quiet >> "$LOG_FILE" 2>&1
        fi
        popd > /dev/null
    fi
done

# Cleanup log
if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
