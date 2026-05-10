# Windows Git Sync Configuration

This document describes the Windows-specific components and behaviors used to facilitate automated Git synchronization for this environment.

## Overview
Because the core synchronization engine is a Bash script (`sync_repos.sh`), Windows requires a few helper components to handle scheduling and background execution without interrupting the user.

## Components

### 1. The Trigger (Windows Task Scheduler)
A scheduled task is used to provide the "heartbeat" for the system.

*   **Task Name:** `\GitRepoSync`
*   **Trigger:** Every 2 minutes, indefinitely.
*   **Action:** Runs the VBScript wrapper.
*   **Execution Policy:** Runs only when the user is logged on (to ensure access to SSH keys and network context).

### 2. The Invisibility Wrapper (VBScript)
To prevent a command prompt window from popping up every 2 minutes, the system uses a VBScript "launcher."

*   **Path:** `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup\start_sync_hidden.vbs`
*   **Code:**
    ```vbs
    Set WshShell = CreateObject("WScript.Shell")
    ' Run bash hidden
    WshShell.Run "bash.exe -c \"/c/Users/sampa/bin/sync_repos.sh\"", 0, False
    ```
*   **Function:** The `0` parameter in `WshShell.Run` instructs Windows to run the process in a hidden window.

### 3. Execution Environment (Git Bash / WSL)
The system relies on a POSIX-compatible environment to execute the `.sh` script.

*   **Binary:** `bash.exe` (mapped from Git for Windows).
*   **Path Mapping:** Uses `/c/` prefix for `C:\` drive paths to bridge Windows and Bash file systems.

## Troubleshooting Windows Behavior

### Task Status
You can check if the task is running via PowerShell:
```powershell
schtasks /query /tn "GitRepoSync" /v /fo LIST
```

### Process Visibility
Since the script runs hidden, you won't see it in the taskbar. To verify it is running, check the Task Manager for `bash.exe` or `git.exe` processes, or monitor the log file:
```powershell
Get-Content -Tail 20 $HOME\bin\sync_repos.log
```

### SSH Agent Issues
On Windows, the sync may fail if the SSH agent is not running or the key is not loaded. Ensure the "OpenSSH Authentication Agent" service is set to Automatic and your key is added via `ssh-add`.
