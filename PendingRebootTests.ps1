#Intro
Clear-Host;
Write-Host "PENDING REBOOT TESTS `n" -ForegroundColor Blue -BackgroundColor White;
Write-Host "Check if nodes on target list require reboot `n";

<# --- Functions ---#>
# Log info
function LogInfo {
$Global:logtime = Get-Date -Format yyyy-MM-dd_HH-mm-ss
$Global:logname = $Global:logtime + “_PendingReboots.txt”
$Global:log = 'C:\Logs\' + $Global:logname
Write-Host "Log will be written to " $Global:log
};

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

# The file "targets_PendingReboot.txt" is used as a target list option by the script "RebootTargets.ps1"
$TargetsList = "C:\scripts\targets_PendingReboot.txt"
$WriteRebootTargetsList = $PC | Out-File -Append -Force -FilePath $TargetsList;
if (Test-Path -Path $TargetsList) {
    Write-Host "Reboot Targets output file already exists.";
    Read-Host -Prompt "Press enter to delete the file and continue, or CRTL+C to quit";
    Remove-Item $TargetsList
    }

<# ------------ #>
<# Begin processes #>
adminAuth;
LogInfo;
do {
	Menu;
    # === TESTS === #
    $pendingRebootTests = @(
        @{
            Name = 'RebootPending'
            Test = { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Name 'RebootPending' -ErrorAction Ignore }
            TestType = 'ValueExists'
        }
        @{
            Name = 'RebootRequired'
            Test = { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction Ignore }
            TestType = 'ValueExists'
        }
        @{
            Name = 'PendingFileRenameOperations'
            Test = { Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Ignore }
            TestType = 'NonNullValue'
        }
    )

    # === For loop === #
    foreach ($PC in $Global:list) {
        Write-Host `n$PC
        foreach ($test in $pendingRebootTests) {
            $result = Invoke-Command -ComputerName $PC -ScriptBlock $test.Test -ErrorAction SilentlyContinue
            if (($test.TestType -eq 'ValueExists' -and $result) -OR ($test.TestType -eq 'NonNullValue' -and $result -and $result.($test.Name))) {
                Write-Host "   "$test.Name":"$true -ForegroundColor Red;
                $PC | Out-File -Append -Force -FilePath $TargetsList;
            } else {
                Write-Host "   "$test.Name":"$false
            }
        }
    }
    
	# === Trim end of output file === #
    $content = [System.IO.File]::ReadAllText($TargetsList)
    $content = $content.Trim()
    [System.IO.File]::WriteAllText($TargetsList, $content)
	
    # === END TESTS === #

	do { 
        $again = Read-Host "`nDo you want to start again? (Y/N)"
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
$variableArray = @('list','cred','logtime','logname','log')
Remove-Variable -Name $variableArray -Scope Global
#>
# End
Read-Host -Prompt "Press 'Enter' to exit..."
