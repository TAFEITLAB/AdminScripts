# Intro
Clear-Host;
Write-host "Checking Windows activation status on local host `n" -ForegroundColor Blue -BackgroundColor White;

# Begin
$Status = (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" | where PartialProductKey).licensestatus;
If ($Status -ne 1) {Write-Host "Windows is NOT activated on $env:computername" -ForegroundColor DarkRed -BackgroundColor White} ElseIf ($Status -eq 1) {Write-Host "Windows is activated on $env:computername" -ForegroundColor Green};

#End
Read-Host -Prompt "Press 'Enter' to exit...";