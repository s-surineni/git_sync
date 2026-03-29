Set WshShell = CreateObject("WScript.Shell")
' 0 = Hide window
WshShell.Run """C:\Program Files\Git\bin\bash.exe"" --noprofile --norc -c C:/Users/sampa/bin/sync_repos.sh", 0, False
