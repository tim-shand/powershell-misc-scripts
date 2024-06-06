<#
.Synopsis
   List installed applications within Win32_Product and provide uninstall option. 
.DESCRIPTION
   Includes text based navigation menu. 
.NOTES
   Intended to be used as a template or base for other scripts/functions. 
#>

### Functions ###
function Get-InstalledApps {
    $appListFull=@()
    $appListFull = Get-WmiObject Win32_Product | Sort-Object Name
    $c=0
    ForEach($app in $appListFull){        
        Write-Host "[$c] $($app.Name) ($($app.Vendor))"
        $c+=1
    }
}

function Remove-InstalledApp {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,Position=0)]$UseGUI,
        [Parameter(Mandatory=$false,Position=0)]$Silent
    )
    Get-InstalledApps
    $appListFull = Get-WmiObject Win32_Product | Sort-Object Name
    [int]$listEnd = (($appListFull.Length) -1)

    $delSelect = $NULL

    while($delSelect -isnot [int] -and ($delSelect -notin 0..$listEnd)){        
        Try{
            Write-Host "`r`nPlease select an application to remove (enter number from list)" -ForegroundColor Yellow
            [int]$delSelect = Read-Host -Prompt "Application Number" -ErrorAction SilentlyContinue
            if($delSelect -isnot [int] -and ($delSelect -notin 0..($appListFull.Length)-1)){
                Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
            } else{
                # Uninstall Process                
                if($UseGUI){ # GUI uninstall.
                    Write-Host "Uninstall application (GUI)" -ForegroundColor Yellow
                    while($confirm -notin('Y','y','N','n')){
                        Try{
                            Write-Host "Warning: Confirm removal of application '$($appListFull[$delSelect].Name)' [$delSelect]" -ForegroundColor Red
                            $confirm = Read-Host "Do you wish to proceed? (Y/N)"
                            if($confirm -in ('Y','y')){
                                Write-Host "`r`nUninstalling application..." -ForegroundColor Yellow
                                Try{
                                    #$removal = $appListFull[$delSelect].Uninstall()
                                    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/uninstall $($appListFull[$delSelect].IdentifyingNumber)" -wait
                                    Write-Host "`r`nUninstall complete." -ForegroundColor Green
                                } Catch{
                                    $err = $_.Exception.Message
                                    Write-Host "`r`nUninstall failed to complete.`r`n$err" -ForegroundColor Yellow
                                }
                            } elseif($confirm -in ('N','n')){
                                Write-Host "`r`nUninstall aborted." -ForegroundColor Magenta
                            }else{
                                Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
                            }
                        } Catch{
                            Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
                        }
                    }
                } else{
                    # Silent uninstall via MSIEXEC
                    Write-Host "Uninstall application (Silent)" -ForegroundColor Yellow
                    while($confirm -notin('Y','y','N','n')){
                        Try{
                            Write-Host "Warning: Confirm removal of application '$($appListFull[$delSelect].Name)' [$delSelect]" -ForegroundColor Red
                            $confirm = Read-Host "Do you wish to proceed? (Y/N)"
                            if($confirm -in ('Y','y')){
                                Write-Host "`r`nUninstalling application..." -ForegroundColor Yellow
                                Try{
                                    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList @("/uninstall $($appListFull[$delSelect].IdentifyingNumber)","/norestart","/quiet") -wait
                                    Write-Host "`r`nUninstall complete." -ForegroundColor Green
                                } Catch{
                                    $err = $_.Exception.Message
                                    Write-Host "`r`nUninstall failed to complete.`r`n$err" -ForegroundColor Yellow
                                }
                            } elseif($confirm -in ('N','n')){
                                Write-Host "`r`nUninstall aborted." -ForegroundColor Magenta
                            }else{
                                Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
                            }
                        } Catch{
                            Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
                        }
                    }
                } 

            }
        } Catch{
            Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
        }
    }
}

# Main Menu
function MainMenu {    
    while($menu -ne 4){
        Try{
            Write-Host "`r`n--------------------------------------" -ForegroundColor Yellow
            Write-Host "### Uninstall Application Utility ###" -ForegroundColor Yellow
            Write-Host "--------------------------------------" -ForegroundColor Yellow
            Write-Host "`r`nPlease select a task from the menu: `n" -ForegroundColor Green
            Write-Host "1. List installed applications.`n2. Uninstall application (GUI).`n3. Uninstall application (Silent).`n4. Exit.`n"
            $menu = (Read-Host -Prompt "Please select a task number" -ErrorAction SilentlyContinue)
            if($menu -notin (1,2,3,4)){
                Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
            }
            switch ($menu) {
                1 {Get-InstalledApps}
                2 {Remove-InstalledApp -UseGUI $True}
                3 {Remove-InstalledApp -Silent $True}
                4 {Write-Host "Exiting...`n`r" -ForegroundColor Yellow}
            }
        }
        Catch{
            Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
        }
    }
}

##### Main #####
MainMenu
