# git_sync

A collection of scripts to automatically synchronize git repositories every 2 minutes.

## Features
- Cross-platform support (Windows and Linux/Unix)
- External configuration file (per-machine repo lists)
- Auto-detects default branch (main or master)
- Single-run execution (ideal for schedulers)
- Automatic commit of local changes
- Activity logging with auto-cleanup
- No persistent background process required

## Schedulers (Recommended)

To run this script every 2 minutes without keeping a terminal open:

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

### Linux (Cron)
Add this to your crontab:
```bash
# Open crontab editor
crontab -e

# Add this line
*/2 * * * * ~/bin/sync_repos.sh
```

## Scripts
- `sync_repos.sh`: The main bash script that performs the sync (pull/add/commit/push).
- `sync_repos.ps1`: PowerShell equivalent of the sync script.
- `setup_autostart.sh`: Utility to set up login-based autostart (alternative to schedulers).

## Logs
Logs are stored in `~/bin/sync_repos.log` and automatically kept to the last 1000 lines.

## Configuration

Repos are configured in `~/.sync_repos.conf` (one path per line). Create it on each machine:

```bash
./sync_repos.sh --init
```

Then edit `~/.sync_repos.conf`:
```bash
# Sync Repos Configuration
# Add one repository path per line (use # for comments)

$HOME/dotfiles
$HOME/myconfig/settings
$HOME/projects/my_notes
```

## Usage

```bash
./sync_repos.sh --help           # Show help
./sync_repos.sh --init           # Create sample config
./sync_repos.sh                  # Run sync
```

## Adding New Repositories

1.  **Edit config**: Add the full path to `~/.sync_repos.conf`
    ```bash
    $HOME/path/to/your/new_repo
    ```
2.  **Verify**: Check the log to ensure the new repo is being processed:
    ```bash
    tail -f ~/bin/sync_repos.log
    ```
