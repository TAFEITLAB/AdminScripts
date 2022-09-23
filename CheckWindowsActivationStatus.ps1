# Intro
Clear-Host;
Write-host "Checking Windows activation status on listed PCs `n" -ForegroundColor Blue -BackgroundColor White;
Write-Host "This script will return all results, success or failure.";

#---- FUNCTIONS ----#
function LabAdminAuthentication {
    # Get domain admin credentials
    Write-host "Enter your domain administrator credentials `n or close the script window to quit";
    Pause;
    $PromptCaption = "Administrator credentials required";
    $PromptMessage = "Please input your domain credentials";
    $CredentialType = [System.Management.Automation.PSCredentialTypes]::Domain
    $ValidateOption = [System.Management.Automation.PSCredentialUIOptions]::ValidateUserNameSyntax
    if($Global:cred = $host.ui.PromptForCredential($PromptCaption,$PromptMessage,"","",$CredentialType,$ValidateOption)){}else{exit};
}

<#
NB: The following menu options rely on the existence of text files containing a list of all relevant target nodes, one node per line.
e.g. "targets_Servers.txt" will list the FQDN of all Servers in the domain, "targets_room1.txt" will only list the FQDNs of workstations on Room 1, etc.
#>
# Menu
function Menu {
    # Menu options
    # - Servers and workstations
    $all = New-Object System.Management.Automation.Host.ChoiceDescription '&All', 'All workstations and servers';
    # - Servers
    $servers = New-Object System.Management.Automation.Host.ChoiceDescription '&Servers', 'All servers';
    # - Workstations
    $workstations = New-Object System.Management.Automation.Host.ChoiceDescription '&Workstations', 'All workstations';
    # - Room 1 workstations
    $room1 = New-Object System.Management.Automation.Host.ChoiceDescription 'room&1', 'Room 1 workstations';
    # - Room 2 workstations
    $room2 = New-Object System.Management.Automation.Host.ChoiceDescription 'room&2', 'Room 2 workstations';
    # - Options
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($all, $servers, $workstations, $room1, $room2);

    # Menu
    # - Target list folder
    $targetListFolder = 'C:\scripts'
    # - Target options
    $title = "Target list options";
    $message = "Please select a target list, or close this dialogue box to quit.";
    $selection = $host.ui.PromptForChoice($title, $message, $options, 0);
    # - Switch
    switch ($selection)
        {
            0 { 
                $listFile = "$targetListFolder\targets_All.txt"
                $userChoice = "You chose 'All'"
                }
            1 {  
                $listFile = "$targetListFolder\targets_Servers.txt"
                $userChoice = "You chose 'Servers'"
                }
            2 {  
                $listFile = "$targetListFolder\targets_Workstations.txt"
                $userChoice = "You chose 'Workstations'"
                }
            3 { 
                $listFile = "$targetListFolder\targets_room1.txt"
                $userChoice = "You chose 'Room 1'"
                }
            4 { 
                $listFile = "$targetListFolder\targets_room2.txt"
                $userChoice = "You chose 'Room 2'"
                }
        };

    # Echo user choices
    Write-host $userChoice;
    Write-Host "Fetching list of hosts from $listFile `n";

    # Get content of list file
	# - NB: The Global: prefix is required to access the variable outside of this function.
	#       It must be cleared at the end of the script, as Global variables will not clear automatically.
    $Global:list = Get-Content $listFile;
}

function WindowsActivationStatus{
    # For Loop
    foreach ($PC in $Global:list) {
    Invoke-Command -ComputerName $PC -Credential $Global:cred -ScriptBlock {$Status = (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" | where PartialProductKey).licensestatus;
    If ($Status -ne 1) {Write-Host "Windows is NOT activated on $env:computername" -ForegroundColor DarkRed -BackgroundColor White} ElseIf ($Status -eq 1) {Write-Host "Windows is activated on $env:computername" -ForegroundColor Green}
    }
    };
}

#---- END FUNCTIONS ----#
#---- PROCESSES ----#
LabAdminAuthentication;
do {
	Menu;
	WindowsActivationStatus;
	do { 
      $again = Read-Host "Do you want to start again? (Y/N)"
      If (($again -eq "Y") -or ($again -eq "N"))
      { $go = $true
      }
      Else
      { Write-Host "Invalid input. Please try again" -ForegroundColor Red;
      }
   }Until($go)

}
Until($again -eq "N")
#---- END PROCESSES ----#

#---- FINISH SCRIPT ----#
#Remove-Variable NAME -Scope Global;
Remove-Variable cred -Scope Global;
Remove-Variable list -Scope Global;

# End
Read-Host -Prompt "Press 'Enter' to exit...";