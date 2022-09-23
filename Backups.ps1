<# --- Functions ---#>

# Intro
function Intro {
Clear-Host;
Write-Host "Important Folder Backups `n" -ForegroundColor Blue -BackgroundColor White;
Write-Host "Back up important folders to removable drives `n";
};

#Log info
function LogInfo {
$Global:logtime = Get-Date -Format yyyy-MM-dd_HH-mm-ss
$Global:logname = $Global:logtime + '_Backups.txt'
$Global:log = 'C:\Logs\' + $Global:logname
Write-Host "Log will be written to " $Global:log
};

# Admin authorisation
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
function TargetMenu {
    # Backup storage devices
	# - Fetch the drive letter based on the drive's name in File Explorer. This will ensure the letter is always accurate.
	# - For the user's clarity, include both the drive name and a brief physical description
    $thumbDrive = New-Object System.Management.Automation.Host.ChoiceDescription '&thumbDrive', 'Thumb Drive (Blue USB)';
    $myHDD= New-Object System.Management.Automation.Host.ChoiceDescription '&my-HDD', 'my-HDD (External Desktop Drive)';
    $workDrive = New-Object System.Management.Automation.Host.ChoiceDescription '&Work-Drive', 'Work-Drive (Black portable hard drive)';
    # - Options
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($thumbDrive,$myHDD,$workDrive);
    # - Target options
    $title = "Target list options";
    $message = "Please select a target drive, or close this dialogue box to quit.";
    $selection = $host.ui.PromptForChoice($title, $message, $options, 0);
    # - Switch
    switch ($selection)
        {
            0 { 
                $TargetDrive = Get-Volume -FileSystemLabel thumbDrive;
                $userChoice = "You chose 'thumbDrive'"
                }
            1 {  
                $TargetDrive = Get-Volume -FileSystemLabel my-HDD;
                $userChoice = "You chose 'my-HDD'"
                }
            2 {  
                $TargetDrive = Get-Volume -FileSystemLabel Work-Drive;
                $userChoice = "You chose 'Work-Drive'"
                }
        };

    # Echo user choices
    Write-host $userChoice;
    $Global:TargetDriveLetter = $TargetDrive.DriveLetter;
}


function TestRun {
#Title
Write-Host "Performing test run. Prepare to review files for synchronisation." -ForegroundColor DarkGreen -BackgroundColor White

# Public Downloads
Write-Host "1: Public Downloads" -ForegroundColor Yellow
robocopy 'C:\Users\Public\Downloads' $Global:TargetDriveLetter':\Public Downloads' /MIR /NP /NJS /XD "pwv" /XD "CFG-BKP-VRSN" /XD "PDQ_DB_VRSN" /MT:64 /NOOFFLOAD /R:2 /W:2 /L /tee /log+:$Global:log

# Script user profile folder
Write-Host "2: Your profile folder" -ForegroundColor Yellow
robocopy $env:profilefolder $Global:TargetDriveLetter':\YOURNAME' /MIR /NP /MT:64 /NOOFFLOAD /R:2 /W:2 /L /tee /log+:$Global:log

# Remote log folder
Write-Host "3: Remote logs" -ForegroundColor Yellow
robocopy '\\REMOTE-HOST\C$\logs' $Global:TargetDriveLetter':\REMOTE-HOST\logs' /MIR /NP /MT:64 /NOOFFLOAD /R:2 /W:2 /L /tee /log+:$Global:log

};

function RealRun {
#Title
Write-Host "Performing synchronisation." -ForegroundColor DarkGreen -BackgroundColor White
Write-Host "WARNING: This will remove and overwrite files on the destination. This action cannot be undone." -ForegroundColor Red -BackgroundColor Black
Read-Host -Prompt "Press ENTER to continue or CTRL+C to quit."

Write-Host "Job summaries:" - ForegroundColor Green

# Public Downloads
Write-Host "1: Public Downloads" -ForegroundColor Yellow
robocopy 'C:\Users\Public\Downloads' $Global:TargetDriveLetter':\Public Downloads' /MIR /NFL /NDL /NJH /NP /NS /NC /XD "pwv" /XD "CFG-BKP-VRSN" /XD "PDQ_DB_VRSN" /MT:64 /NOOFFLOAD /R:2 /W:2 /tee /log+:$Global:log

# Script user profile folder
Write-Host "2: Your profile folder" -ForegroundColor Yellow
robocopy $env:profilefolder $Global:TargetDriveLetter':\YOURNAME' /MIR /NFL /NDL /NJH /NP /NS /NC /MT:64 /NOOFFLOAD /R:2 /W:2 /tee /log+:$Global:log

# Remote log folder
Write-Host "3: Remote logs" -ForegroundColor Yellow
robocopy '\\REMOTE-HOST\C$\logs' $Global:TargetDriveLetter':\REMOTE-HOST\logs' /MIR /NFL /NDL /NJH /NP /NS /NC /MT:64 /NOOFFLOAD /R:2 /W:2 /tee /log+:$Global:log
};

function GlobalVariableCleaner {
# Drive letter
Clear-Variable TargetDriveLetter
Remove-Variable TargetDriveLetter
# Log time
Clear-Variable logtime
Remove-Variable logtime
# log name
Clear-Variable logname
Remove-Variable logname
# log filepath
Clear-Variable log
Remove-Variable log
};
<# ------------ #>


<# Begin processes #>
#adminAuth;
do {
    Intro;
    TargetMenu;    
    LogInfo;
    TestRun;
    RealRun;
    GlobalVariableCleaner;
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
Read-Host -Prompt "Press 'Enter' to exit..."