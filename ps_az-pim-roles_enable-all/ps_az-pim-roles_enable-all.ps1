<#
.Synopsis
   Activate all Azure Entra ID PIM roles assigned to the authenticated user.
.DESCRIPTION
  - Requires 'AzureAD Preview' Module (Install-Module AzureADPreview).
.EXAMPLE - Manual execution
  Check-Modules
  $session = Check-AzureSession
  Activate-PimRoles -session $session -reason "Some reason here."
.EXAMPLE - From terminal
   .\Az-PIM-Roles_EnableAll.ps1 -reason "TESTING"
#>

# Variables
param(
    [Parameter][string]$reason
)
if(!($reason)){
    [string]$reason = "BAU Work"
}

# Function: Check required modules and import them. 
function Check-Modules {
    Write-Host -BackgroundColor Magenta "--- Checking/Importing Modules ---"
    $reqModules = @('AzureADPreview')
    [int]$mCount = 0
    ForEach($m in $reqModules){
        $currentModule = (Get-Module -Name $m -ListAvailable).Version
        if($currentModule){
            Try{
                Import-Module $m
                Write-Host "[INFO]: Successfully loaded module '$m'."
                $mCount += 1
            }
            Catch{
                $err = $_.Exception.Message
                Write-Host -ForegroundColor Red "[ERROR]: Failed to load module '$m'.`r`n$err"
                Break
            }
        } else{
            Write-Host -ForegroundColor Yellow "[WARNING]: Required module '$m' is not installed. Please install and try again."
            Break
        }
    }
    Write-Host -ForegroundColor Green "[INFO]: Successfully loaded $mCount/$($reqModules.Count) required modules."
}

# Function: Check for current Azure session, login if not connected. 
function Check-AzureSession {
    $currentSession = $null
    Write-Host -BackgroundColor Magenta "--- Checking Azure Connection ---" 
    Try{
        Write-Host "[INFO]: Checking connection to Azure..." -NoNewline
        $currentSession = Get-AzureADCurrentSessionInfo 2>$null -ErrorAction SilentlyContinue
        if($currentSession){
            Write-Host -ForegroundColor Green " CONNECTED!"
        }
    } 
    Catch{
        Write-Host -ForegroundColor Yellow " NOT CONNECTED!"
        Write-Host -ForegroundColor Yellow "[WARN]: No existing Azure connection. Attempting authentication..." -NoNewline
        Try{
            Connect-AzureAD
            $currentSession = Get-AzureADcurrentSessionInfo 2>$null
            Write-Host -ForegroundColor Green " CONNECTED!"
        }
        Catch{
            $err = $_.Exception.Message
            Write-Host -ForegroundColor Red " FAILED!"
            Write-Host "[ERROR]: Unable to connect to Azure! $err"
        }
    }
    Return $currentSession
}

function Activate-PimRoles($session){
    $myRoles = $NULL
    $allRoles = $NULL
    $allSettings = $NULL
    Write-Host -BackgroundColor Magenta "--- Collecting PIM Role Information ---"
    # Get PIM role information for current user.
    $myId = [string](Get-AzureAdUser -Filter "userPrincipalName eq '$($session.Account | Select -First 1)'").ObjectId
    $myRoles = (Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $($session.TenantId | Select -First 1) -Filter "SubjectId eq '$myId'")
    $allRoles = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadRoles" -ResourceId $($session.TenantId | Select -First 1)) #$session.TenantId)
    $allSettings = (Get-AzureADMSPrivilegedRoleSetting -ProviderId "aadRoles" -Filter "ResourceId eq '$($session.TenantId | Select -First 1)'")

    # Add human readable names to $myRoles
    $i = 1
    ForEach ($role in $myRoles) {
        $roleDisplayName = ""
        $roleDisplayName = ($allRoles | Where-Object {$_.Id -eq $role.RoleDefinitionId}).DisplayName 
        $role | add-member -NotePropertyName "RoleDisplayName" -NotePropertyValue $roleDisplayName
        $role | add-member -NotePropertyName "RoleIndex" -NotePropertyValue $i
        $userMemberSettings = ""
        $userMemberSettings = ($allSettings | Where-Object {$_.RoleDefinitionId -eq $role.RoleDefinitionId}).UserMemberSettings
        $role | add-member -NotePropertyName "maximumGrantPeriodInMinutes" -NotePropertyValue (($userMemberSettings.Setting.split(',') | Select-String -Pattern "maximumGrantPeriodInMinutes") -replace "[^0-9]" , '')
        $i++
        Write-Host "[INFO]: PIM Role = $($role.RoleDisplayName)"
    }

    # Pause and prompt for confirmation.
    $confirm = $NULL
    Write-Host -BackgroundColor Magenta "-----------------------------------------`r`n"
    while($confirm -notin ('y','yes','n','no')){
        $confirm = (Read-Host "Proceed with activating above PIM roles? (Y/N)")
    }
    if($confirm -in ('y','yes')){
        Write-Host -BackgroundColor Magenta "--- Activating PIM Roles ---"
        # Activate each PIM role available. 
        ForEach($r in $myRoles){
            $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
            $schedule.Type = "Once"
            $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $newTime = New-TimeSpan -Minutes $r.maximumGrantPeriodInMinutes
            $schedule.endDateTime = $schedule.StartDateTime+$newTime
            Try{
                Write-Host -ForegroundColor Yellow "Activating PIM Role: $($r.RoleDisplayName)..." -NoNewline
                Open-AzureADMSPrivilegedRoleAssignmentRequest `
                    -ProviderId "aadRoles" `
                    -ResourceId $session.TenantId `
                    -RoleDefinitionId $r.RoleDefinitionId `
                    -SubjectId $myId `
                    -Schedule $schedule `
                    -Type UserAdd `
                    -AssignmentState Active `
                    -Reason "$reason" | Out-Null
                Write-Host -ForegroundColor Green " SUCCESS!"
            }
            Catch{
                $err = $_.Exception.Message
                Write-Host -ForegroundColor Red " FAILED!"
                Write-Host "[ERROR]: Unable to activiate PIM role '$($r.RoleDisplayName)'`r`n$err"
            }    
        }
        Write-Host -ForegroundColor Black -BackgroundColor Green "--- Complete ---"
    } else{
        Write-Host -ForegroundColor Yellow "[WARN]: Activation of PIM roles aborted by user."
    }
}

### MAIN ###
# Check required modules are installed. 
Check-Modules

# Check connection to Azure.
$session = Check-AzureSession

# Activate all PIM roles assigned. 
Activate-PimRoles -session $session

#Disconnect-AzureAD

# EOF
