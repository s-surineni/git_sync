# git_sync

A collection of scripts to automatically synchronize git repositories every 2 minutes.

## Features
- Cross-platform support (Windows and Linux/Unix)
- Single-run execution (ideal for schedulers)
- Automatic commit of local changes
- Activity logging with auto-cleanup
- No persistent background process required

## Schedulers (Recommended)

To run this script every 2 minutes without keeping a terminal open:

### Windows (PowerShell)
Run this once to create the background task (runs invisibly):
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"Start-Process 'C:\Program Files\Git\bin\bash.exe' -ArgumentList '--noprofile', '--norc', '-c', 'C:/Users/sampa/bin/sync_repos.sh' -WindowStyle Hidden`""
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

## Adding New Repositories

To add a new repository to the sync service:

1.  **Update the script**: Add the full path to the `REPOS` array in `~/projects/git_sync/sync_repos.sh`.
    ```bash
    REPOS=(
        "$HOME/dotfiles"
        "c:/path/to/your/new_repo"
    )
    ```
2.  **Apply changes**: On Windows, old bash processes might stay in the background. Run this in **PowerShell** to force the scheduler to use the updated script:
    ```powershell
    Stop-Process -Name bash -Force -ErrorAction SilentlyContinue
    ```
3.  **Verify**: Check the log to ensure the new repo is being processed:
    ```bash
    tail -f ~/bin/sync_repos.log
    ```
