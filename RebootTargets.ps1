#Intro
Clear-Host;
Write-Host "REBOOT TARGETS `n" -ForegroundColor Blue -BackgroundColor White;
Write-Host "Select a target list and send a Force Rebvoot command `n";

<# --- Functions ---#>
function AdminAuth {
    # Get domain admin credentials
    Write-host "Enter your domain administrator credentials `n or close the script window to quit";
    Pause;
    $PromptCaption = "Administrator credentials required";
    $PromptMessage = "Please input your domain credentials";
    $CredentialType = [System.Management.Automation.PSCredentialTypes]::Domain
    $ValidateOption = [System.Management.Automation.PSCredentialUIOptions]::ValidateUserNameSyntax
    if($Global:cred = $host.ui.PromptForCredential($PromptCaption,$PromptMessage,"","",$CredentialType,$ValidateOption)){}else{exit};
}
# Menu
function Menu {
    # Menu options
    # - Servers and workstations
    $all = New-Object System.Management.Automation.Host.ChoiceDescription '&All', 'All workstations and servers';
    # - Servers
    $servers = New-Object System.Management.Automation.Host.ChoiceDescription '&Servers', 'All servers';
    # - Workstations
    $workstations = New-Object System.Management.Automation.Host.ChoiceDescription '&Workstations', 'All workstations';
    # - room1 workstations
    $room1 = New-Object System.Management.Automation.Host.ChoiceDescription 'room&1', 'Room 1 workstations';
    # - Room 2 workstations
    $room2 = New-Object System.Management.Automation.Host.ChoiceDescription 'room&2', 'Room 2 workstations';
    # - Pending Reboot List
    $reboot = New-Object System.Management.Automation.Host.ChoiceDescription '&Reebot', 'Workstations Pending Reboot';
    # - Options
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($all, $servers, $workstations, $room1, $room2,  $reboot);

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
            5 { 
                $listFile = "$targetListFolder\targets_PendingReboot.txt"
                $userChoice = "You chose 'Workstations Pending Reboot'"
                }
        };

    # Echo user choices
    Write-host $userChoice;
    Write-Host "Fetching list of hosts from $listFile `n";

    # Get content of list file
    $Global:list = Get-Content $listFile;
}

# Force Shutdown
function ForceShutdown {
    # For loop
    foreach ($PC in $Global:list) {
            Write-Host "Sending reboot signal to" $PC;
            Restart-Computer -ComputerName $PC -Credential $Global:cred -Force;
    };
}

<# ------------ #>
<# Begin processes #>
adminAuth;
do {
	Menu;
	ForceShutdown;
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
<# ------------ #>
<# Close Script #>
<#
# Clear Global variables
$variableArray = @('list','cred');
Remove-Variable -Name $variableArray; -Scope Global
#>
# End
Read-Host -Prompt "Press 'Enter' to exit..."
