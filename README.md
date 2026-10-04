# git_sync

A script to automatically synchronize git repositories on a schedule (every 2 minutes by default).

## Features
- Cross-platform support (macOS, Linux, Windows)
- External configuration file (per-machine repo lists)
- Auto-discovers git repos under `MULTI_DIRS`
- Auto-detects default branch (main or master)
- Single-run execution (ideal for schedulers)
- Automatic commit of tracked changes (untracked files are never added)
- Optional AI-generated commit messages (Groq)
- Lock file prevents overlapping runs; network check and retries on pull/push
- Activity logging with auto-cleanup
- No persistent background process required

## How a sync works

For each repo, `sync_repos.sh`:
1. Skips the repo if it is not a git repo, has a rebase in progress, is on a detached HEAD, or is not on its default branch.
2. Commits tracked changes (`git add -u`), using an AI message if `~/.groq_api_key` exists, otherwise `Auto-sync from user@host`.
3. Runs `git pull --rebase` (falls back to a merge pull if the rebase fails).
4. Runs `git push` to the default branch.

The whole run is skipped if GitHub is unreachable or another sync is already running.

## Configuration

### Repo list: `~/.sync_repos.conf`

One path per line (`#` for comments, `$HOME` and `~` are expanded). Create a sample on each machine:

```bash
./sync_repos.sh --init
```

Use the config for repos that live outside the auto-discovered directory:
```bash
# Sync Repos Configuration
$HOME/dotfiles
$HOME/path/to/other_repo
```

### Auto-discovery: `MULTI_DIRS`

Every git repo found up to two levels below each directory in `MULTI_DIRS` (space-separated) is synced in addition to the config list. Default: `$HOME/ironman/multi`. Override it per run or in the crontab line:

```bash
MULTI_DIRS="$HOME/playg/multi" ./sync_repos.sh
```

With discovery covering all your repos, the config file can contain comments only.

### AI commit messages (optional)

Put a Groq API key in `~/.groq_api_key`. Without it, commits use the generic message.

## Scheduling (recommended)

### macOS / Linux (cron)

```bash
mkdir -p ~/git_sync        # cron opens the log redirect before the script runs
crontab -e
```

Add this line (adjust the script path and `MULTI_DIRS`):
```bash
*/2 * * * * MULTI_DIRS=$HOME/playg/multi /path/to/git_sync/sync_repos.sh >> $HOME/git_sync/cron.log 2>&1
```

On macOS, if cron cannot read your repos, grant Full Disk Access to `/usr/sbin/cron`.

To uninstall, remove the line while keeping other entries:
```bash
crontab -l | rg -v sync_repos.sh | crontab -
```

### Windows (PowerShell)
Run this once to create the background task (runs completely invisibly):
```powershell
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"C:\Users\sampa\bin\silent_run.vbs`""
$trigger1 = New-ScheduledTaskTrigger -AtLogon
$trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "GitRepoSync" -Action $action -Trigger @($trigger1, $trigger2) -Settings $settings -Force
```

To manage the task:
- **Check status**: `Get-ScheduledTask -TaskName "GitRepoSync"`
- **Delete task**: `Unregister-ScheduledTask -TaskName "GitRepoSync" -Confirm:$false`

## Scripts
- `sync_repos.sh`: The main bash script that performs the sync (commit/pull/push).
- `sync_repos.ps1`: PowerShell equivalent of the sync script.
- `setup_autostart.sh`: Utility to set up login-based autostart (alternative to schedulers).
- `silent_run.vbs`: Hidden launcher used by the Windows scheduled task.

## Usage

```bash
./sync_repos.sh --help           # Show help
./sync_repos.sh --init           # Create sample config
./sync_repos.sh                  # Run sync
```

## Logs
All files live in `~/git_sync/`:
- `sync_repos.log`: the script's log, automatically kept to the last 1000 lines.
- `cron.log`: stray stdout/stderr from cron (normally empty).
- `sync_repos.lock/`: lock directory present only while a sync is running.

```bash
tail -f ~/git_sync/sync_repos.log
```

## Adding New Repositories

- **Under a `MULTI_DIRS` directory**: nothing to do, it is picked up on the next run.
- **Elsewhere**: add the full path to `~/.sync_repos.conf`:
  ```bash
  $HOME/path/to/your/new_repo
  ```

Then check the log to confirm the repo is being processed.
