#!/bin/bash -l

# Load Groq API key from file (works in cron where env vars aren't available)
if [[ -f "$HOME/.groq_api_key" ]]; then
    export GROQ_API_KEY=$(cat "$HOME/.groq_api_key")
fi

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
    echo "AI commit messages: Add your Groq API key to ~/.groq_api_key"
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
# $HOME and ~ are expanded

$HOME/dotfiles
$HOME/myconfig/settings
# $HOME/projects/my_notes
EOF
    echo "Created sample config: $CONFIG_FILE"
    echo "Edit it to add your repository paths."
    exit 0
fi

expand_path() {
    local path="$1"
    path="${path/#\~/$HOME}"
    path="${path//\$HOME/$HOME}"
    printf '%s' "$path"
}

# Read repos from external config file (one repo per line, # for comments)
CONFIG_FILE="$HOME/.sync_repos.conf"
REPOS=()

if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        REPOS+=("$(expand_path "$line")")
    done < "$CONFIG_FILE"
else
    echo "Config file not found: $CONFIG_FILE" >&2
    echo "Run with --init to create a sample config file." >&2
    exit 1
fi

# Auto-discover all git repos under MULTI_DIRS (space-separated paths)
MULTI_DIRS="${MULTI_DIRS:-$HOME/ironman/multi}"
for MULTI_DIR in $MULTI_DIRS; do
    MULTI_DIR="$(expand_path "$MULTI_DIR")"
    if [ -d "$MULTI_DIR" ]; then
        while IFS= read -r -d '' dir; do
            repo_dir="$(dirname "$dir")"
            already_included=false
            for r in "${REPOS[@]}"; do
                [[ "$r" == "$repo_dir" ]] && already_included=true && break
            done
            $already_included || REPOS+=("$repo_dir")
        done < <(find "$MULTI_DIR" -maxdepth 2 -name ".git" -type d -print0 2>/dev/null)
    fi
done

LOG_DIR="$HOME/git_sync"
LOG_FILE="$LOG_DIR/sync_repos.log"
LOCK_FILE="$LOG_DIR/sync_repos.lock"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

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
            model: "llama-3.1-8b-instant",
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

retry() {
    local n=0 max=3 delay=5
    until [[ $n -ge $max ]]; do
        "$@" && return
        n=$((n+1))
        if [[ $n -lt $max ]]; then
            echo "  Retry $n/$max after ${delay}s..." >> "$LOG_FILE"
            sleep $delay
        fi
    done
    return 1
}

git_dir() {
    git rev-parse --git-dir 2>/dev/null
}

in_rebase() {
    local gd
    gd="$(git_dir)" || return 1
    [[ -d "$gd/rebase-merge" || -d "$gd/rebase-apply" ]]
}

# Skip only an in-progress rebase you started. Dirty merges are still forced through.
skip_in_progress_rebase() {
    if in_rebase; then
        echo "  In-progress rebase detected, skipping this repo" >> "$LOG_FILE"
        return 0
    fi
    return 1
}

if ! mkdir "$LOCK_FILE" 2>/dev/null; then
    if [[ -f "$LOCK_FILE/pid" ]] && kill -0 "$(cat "$LOCK_FILE/pid")" 2>/dev/null; then
        log "Another sync is already running (pid $(cat "$LOCK_FILE/pid")), skipping"
        exit 0
    fi
    rm -rf "$LOCK_FILE"
    mkdir "$LOCK_FILE" || exit 1
fi
echo $$ > "$LOCK_FILE/pid"
trap 'rm -rf "$LOCK_FILE"' EXIT

if ! git ls-remote --exit-code https://github.com/git/git.git HEAD &>/dev/null; then
    log "Network unavailable (cannot reach GitHub), skipping sync"
    exit 1
fi

for repo in "${REPOS[@]}"; do
    log "Checking repo: $repo"
    if [ -d "$repo" ]; then
        log "Syncing $repo..."

        pushd "$repo" > /dev/null || continue

        if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "  Not a git repository, skipping" >> "$LOG_FILE"
            popd > /dev/null
            continue
        fi

        if skip_in_progress_rebase; then
            popd > /dev/null
            continue
        fi

        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        DEFAULT_BRANCH=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
        if [[ -z "$DEFAULT_BRANCH" ]]; then
            DEFAULT_BRANCH=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|^origin/||')
        fi
        DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}

        if [[ "$current_branch" == "HEAD" ]]; then
            echo "  Detached HEAD, skipping" >> "$LOG_FILE"
            popd > /dev/null
            continue
        fi

        if [[ "$current_branch" != "$DEFAULT_BRANCH" ]]; then
            echo "  On '$current_branch' (default is '$DEFAULT_BRANCH'), skipping" >> "$LOG_FILE"
            popd > /dev/null
            continue
        fi

        # Tracked changes only: staged, unstaged, and deletions. Never untracked (??).
        if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
            echo "  Found changes in tracked files, committing before pull..." >> "$LOG_FILE"
            local_diff=$( { git diff --cached; git diff; } | head -400 )
            commit_msg=$(generate_commit_message "$local_diff")
            echo "  Commit message: $commit_msg" >> "$LOG_FILE"

            git add -u
            if ! git commit -m "$commit_msg" --quiet >> "$LOG_FILE" 2>&1; then
                echo "  Commit failed or nothing to commit" >> "$LOG_FILE"
            fi
        fi

        if ! retry git pull --rebase origin "$DEFAULT_BRANCH" --quiet >> "$LOG_FILE" 2>&1; then
            echo "  Rebase failed, aborting and trying merge..." >> "$LOG_FILE"
            git rebase --abort 2>/dev/null
            if ! retry git pull origin "$DEFAULT_BRANCH" --quiet >> "$LOG_FILE" 2>&1; then
                echo "  Pull/merge failed" >> "$LOG_FILE"
            fi
        fi

        if ! retry git push origin "$DEFAULT_BRANCH" --quiet >> "$LOG_FILE" 2>&1; then
            echo "  Push failed" >> "$LOG_FILE"
        fi

        popd > /dev/null
    else
        log "Directory not found: $repo"
    fi
done

if [ -f "$LOG_FILE" ]; then
    tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
