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
    echo ""
    echo "Set GROQ_API_KEY in your environment for AI-generated commit messages."
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

LOG_FILE="$HOME/git_sync/sync_repos.log"

generate_commit_message() {
    local diff="$1"
    if [[ -z "$GROQ_API_KEY" || -z "$diff" ]]; then
        echo "Auto-sync from $USER@$(hostname)"
        return
    fi
    local msg
    msg=$(curl -s -w "\n%{http_code}" https://api.groq.com/openai/v1/chat/completions \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg diff "$diff" '{
            model: "llama3-8b-8192",
            messages: [
                {role: "system", content: "Generate a concise git commit message (max 72 chars, no quotes, no explanation). Describe what changed."},
                {role: "user", content: "Diff:\n" + $diff}
            ],
            temperature: 0.3,
            max_tokens: 50
        }')" 2>/dev/null)
    local status=$(echo "$msg" | tail -1)
    msg=$(echo "$msg" | sed '$d' | jq -r '.choices[0].message.content' 2>/dev/null | tr -d '"' | head -1)
    if [[ "$status" != "200" || -z "$msg" ]]; then
        echo "Auto-sync from $USER@$(hostname)"
    else
        echo "$msg"
    fi
}

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
            local_diff=$(git diff --cached | head -200)
            commit_msg=$(generate_commit_message "$local_diff")
            echo "  Commit message: $commit_msg" >> "$LOG_FILE"
            git commit -m "$commit_msg" --quiet
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
