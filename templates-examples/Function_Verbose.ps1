param(
    [string]$appendPath = "\AppData\Local\Microsoft\Teams\current",
    [int]$ageThresholdMonths = -6
)

function Get-UserProfileOldMSTeams {
    [CmdletBinding()] # Allow advanced function capabilities (Verbose, ErrorAction etc.)
    param(
        [Parameter(Mandatory)] # Forces script to require the variable.
        [string]$appendPath, # Validate the variable input, if not a string, then complain. 
        [Parameter(Mandatory)]
        [int]$ageThresholdMonths,
        $VerbosePreference = "SilentlyContinue"
    )
    # Loop through each user profile (excluding system accounts). 
    Begin{
        $profiles = Get-WMIObject -class Win32_UserProfile | ?{$_.Special -eq $false}
        Write-Host "[$(Get-Date)] [ BEGIN ] Starting scan for old MS Teams. Scanning $($profiles.count) user profiles on $($env:computername)."
        [int]$i = 0 # Set progress bar counter.
        [int]$old = 0
        [int]$removed = 0
    }
    Process{
        $profiles = Get-WMIObject -class Win32_UserProfile | ?{$_.Special -eq $false}
        $profiles | ForEach-Object{
            $teamsDir = ($_.LocalPath + $appendPath)
            $teamsEXE = ($teamsDir + "\teams.exe")
            # Check for existence of Teams directory.
            Write-Verbose -Message "[$(Get-Date)] [PROCESS] Checking: $teamsDir"
            if(Test-Path -Path $teamsEXE){
                Write-Verbose -Message "[$(Get-Date)] [PROCESS] -- Found: $teamsEXE"
                # Check if the Teams.exe file has been updated in the last 'x' months.
                Write-Verbose -Message "[$(Get-Date)] [PROCESS] -- Checking LastWrite date on executable..." 
                if(Get-ChildItem -Path $teamsEXE | ?{$_.LastWriteTime -lt (Get-Date).AddMonths($ageThresholdMonths)}){
                    $old++
                    Write-Verbose -Message "[$(Get-Date)] [PROCESS] -- Teams.exe is older than $ageThresholdMonths months. Removing..."
                    Write-Host "[$(Get-Date)] [PROCESS] Found: $teamsEXE [$((Get-ChildItem -Path $teamsEXE).LastWriteTime)]"
                    Write-Host "[$(Get-Date)] [PROCESS] Removing: $teamsEXE..." -NoNewline
                    Try{
                        Remove-Item -Path $teamsDir -Recurse -Force
                        Write-Host " [DONE]"
                        $removed++
                    }
                    Catch{
                        $err = $_.Exception.Message
                        Write-Host " [FAILED]"
                        Write-Verbose -Message "[$(Get-Date)] [PROCESS] $err"
                    }                    
                } else{
                    Write-Verbose -Message "[$(Get-Date)] [PROCESS] -- Teams.exe is not older than $ageThresholdMonths. Ignore."
                }
            }
            $i = $i+1 # Increment the progress bar counter. 
            Write-Progress -Activity "Searching for MS Teams..." -Status "Progress:" -PercentComplete ($i/($profiles).count*100)
        }
        $teamsDir = $null
        $teamsEXE = $null
    }
    End{
        Write-Host "[$(Get-Date)] [  END  ] Scan Complete. Old Teams installs removed: $old/$removed"
        #Return 0
    }
}

### Main ###
Get-UserProfileOldMSTeams -appendPath $appendPath -ageThresholdMonths -6 -Verbose
############