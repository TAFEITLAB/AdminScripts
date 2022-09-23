#Intro
Clear-Host;
Write-host "List available admin scripts" -ForegroundColor Blue -BackgroundColor White;
Write-Host "Only .bat file names are case sensitive.`nSimply type the file name and press ENTER to run.`n";

Get-ChildItem -Path ("C:\scripts","C:\Users\USERNAME\Other_Scripts") -File | Where {$_.extension -in ".ps1",".bat"} | Select -exp BaseName
Write-Host "";
# End