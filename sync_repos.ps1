# List of repositories to sync
$repos = @(
    "C:\Users\sampa\dotfiles",
    "C:\Users\sampa\myconfig\settings"
)

Write-Host "Starting repo sync service (every 2 minutes)..."
Write-Host "Press Ctrl+C to stop."

while ($true) {
    foreach ($repo in $repos) {
        if (Test-Path $repo) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Syncing $repo..." -ForegroundColor Cyan
            
            # Change to repo directory
            Push-Location $repo
            
            try {
                # Pull latest changes
                git pull --rebase --quiet
                
                # Check if there are local changes to push
                $status = git status --porcelain
                if ($null -ne $status) {
                    Write-Host "  Found local changes, committing and pushing..." -ForegroundColor Yellow
                    git add .
                    git commit -m "Auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" --quiet
                    git push --quiet
                } else {
                    # Even if no local changes, try to push in case of unpushed commits
                    git push --quiet
                }
            } catch {
                Write-Host "  Error syncing $repo" -ForegroundColor Red
            }
            
            Pop-Location
        } else {
            Write-Host "  Path not found: $repo" -ForegroundColor Red
        }
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Wait for 2 minutes..."
    Start-Sleep -Seconds 120
}
