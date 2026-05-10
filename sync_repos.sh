#!/bin/bash

# Show help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Sync multiple git repositories (auto-commit, pull, push)."
    echo ""
    echo "Options:"
    echo "  --init, --generate-config  Create sample ~/.sync_repos.conf"
    echo "  --help, -h                 Show this help message"
    echo ""
    echo "Configuration: ~/.sync_repos.conf (one repo path per line)"
    exit 0
fi

# Generate sample config if requested
if [[ "$1" == "--init" || "$1" == "--generate-config" ]]; then
    CONFIG_FILE="$HOME/.sync_repos.conf"
    if [ -f "$CONFIG_FILE" ]; then
        echo "Config file already exists: $CONFIG_FILE"
        exit 0
    fi
    cat > "$CONFIG_FILE" << 'EOF'
# Sync Repos Configuration
# Add one repository path per line (use # for comments)

$HOME/dotfiles
$HOME/myconfig/settings
# $HOME/projects/my_notes
EOF
    echo "Created sample config: $CONFIG_FILE"
    echo "Edit it to add your repository paths."
    exit 0
fi

# Read repos from external config file (one repo per line, # for comments)
CONFIG_FILE="$HOME/.sync_repos.conf"
REPOS=()

if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line; do
        [[ -n "$line" && ! "$line" =~ ^# ]] && REPOS+=("$line")
    done < "$CONFIG_FILE"
else
    echo "Config file not found: $CONFIG_FILE" >&2
    echo "Run with --init to create a sample config file." >&2
    exit 1
fi

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

        # Detect default branch (main or master)
        DEFAULT_BRANCH=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's/^origin\///' || echo "main")
        
        # Pull latest changes from origin
        git pull origin "$DEFAULT_BRANCH" --quiet >> "$LOG_FILE" 2>&1

        # Push any local commits
        git push origin "$DEFAULT_BRANCH" --quiet >> "$LOG_FILE" 2>&1
        
        popd > /dev/null
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Directory not found: $repo" >> "$LOG_FILE"
    fi
done

# Keep only the last 1000 lines of the log to prevent it from growing too large
if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
