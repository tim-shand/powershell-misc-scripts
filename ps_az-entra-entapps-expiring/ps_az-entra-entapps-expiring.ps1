<#
.Synopsis
   Export CSV for applications with expiring secrets or certificates.  
.DESCRIPTION
   Connect to EntraID (Azure AD) and export CSV of enterprise apps and app registrations with secrets/certificates due to expire.
.INPUTS
 -
.OUTPUTS
   CSV File: AzureAD_EntApps_ExpiryDue_<Date>.csv.
.NOTES
   Requires AzureADPreview Powershell module.
#>

param(
	[int]$daysThreshold
)

### Functions ###
# Function: Check required modules and import them. 
function Check-Modules {
    Write-Host -BackgroundColor Magenta "--- Checking/Importing Modules ---"
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
            Install-Module -Name $m -Force
            Break
        }
    }
    Write-Host -ForegroundColor Green "[INFO]: Loaded $mCount/$($reqModules.Count) required modules."
}


# Function | Get-AzureADConnection: Confirm active sesssion or connect to new session.
function Get-AzureADConnection {
    $currentSession = Get-AzureADCurrentSessionInfo
    if(!($currentSession)){
        Write-Host "WARNING: Not currently connected to Azure, attempting connection..." -ForegroundColor Yellow
        Try{
            $azConn = Connect-AzureAD
            $currentSession = Get-AzureADCurrentSessionInfo
            Do {
                $response = (Read-Host -Prompt "Proceed as '$($currentSession.Account)' in tenant '$($currentSession.TenantDomain)' [Y/N]")
                if($response -in ("n","no")){
                    Write-Host "WARNING: User selected not to proceed. Abort." -ForegroundColor Yellow
                    $currentSession = $null
                    Return $currentSession
                } 
            }
            Until ($response = "Y")
        }
        Catch{
            $err = $_.Exception.Message
            Write-Host "ERROR: Connection attempt failed. $err" -ForegroundColor Yellow
        }
    } else{
        Write-Host "INFO: Existing Azure connection found. Proceeding..." -ForegroundColor Yellow
        Do {
            $response = (Read-Host -Prompt "Proceed as '$($currentSession.Account)' in tenant '$($currentSession.TenantDomain)' [Y/N]")
            if($response -in ("n","no")){
                Write-Host "WARNING: User selected not to proceed. Abort." -ForegroundColor Yellow
                $currentSession = $null
                Return $currentSession
            } 
        }
        Until ($response = "Y")
        Return $currentSession
    }
}

# Function | Get-AzAppExpiry: List app resigrations and check for expiry. 
# Loop list of apps and collect secrets. Check each against expiry date. 
function Get-AzAppExpiry {
    Write-Host "--- Starting application expiry checks ---" -ForegroundColor Yellow
    Write-Host "INFO: Include already expired = $alreadyExpired"
    $resultObj = @()
    $counter = 0
    ForEach($app in $Applications){
        $counter += 1
        Try{
            $AppCreds = Get-AzureADApplication -ObjectId $($app.ObjectId) | select PasswordCredentials, KeyCredentials
            $secrets = $AppCreds.PasswordCredentials
            $certs = $AppCreds.KeyCredentials
            $appOwner = Get-AzureADApplicationOwner -ObjectId $app.ObjectId
            $appOwnerUN = $appOwner.UserPrincipalName -join ";"
            $appOwnerId = $appOwner.ObjectID -join ";"
            if ($appOwner.UserPrincipalName -eq $null) {
                $appOwnerUN = [string]$appOwner.DisplayName + " ** This is an Application **"
            }
            if ($appOwner.DisplayName -eq $null) {
                $appOwnerUN = "** No Owner **"
            }

            Write-Host "Checking App [$($counter)/$($Applications.Count)]: $($app.DisplayName) [Secrets: $($secrets.Count) | Certificates: $($certs.count)]"

            # Exclude already expired
            if($alreadyExpired = $false){
                # Loop each secret and compare end date. 
                ForEach($s in $secrets){
                    $operation = ($s.EndDate - $now)
                    [int]$opDays = $operation.Days
                    if(($opDays -le $daysThreshold -and $opDays -gt 0)){
                        Write-Host "- Adding to results (Secret Expires: $opDays Days)." -ForegroundColor Yellow
                        $secretObj = [pscustomobject] @{
                            AppName = $app.DisplayName
                            AppId = $app.AppId
                            SecretStartDate = $s.StartDate
                            SecretEndDate = $s.EndDate
                            SecretExpiryDays = $opDays
                            CertStartDate = "---"
                            CertEndDate = "---"
                            CertExpiryDays = "---"
                            Owner = $appOwnerUN
                        }
                        $resultObj += $secretObj # Add test results to result object.                        
                    }
                }

                # Loop each certificate and compare end date.
                ForEach($c in $certs){
                    $operation = ($c.EndDate - $now)
                    [int]$opDays = $operation.Days
                    if(($opDays -le $daysThreshold -and $opDays -gt 0)){
                        Write-Host "- Adding to results (Cert Expires: $opDays Days)." -ForegroundColor Yellow
                        $certObj = [pscustomobject] @{
                            AppName = $app.DisplayName
                            AppId = $app.AppId
                            SecretStartDate = "---"
                            SecretEndDate = "---"
                            SecretExpiryDays = "---"
                            CertStartDate = $c.StartDate
                            CertEndDate = $c.EndDate
                            CertExpiryDays = $opDays
                            Owner = $appOwnerUN
                        }
                        $resultObj += $certObj # Add test results to result object.
                    }
                }
            } else{
                # Include already expired
                # Loop each secret and compare end date. 
                ForEach($s in $secrets){
                    $operation = ($s.EndDate - $now)
                    [int]$opDays = $operation.Days
                    if($opDays -le $daysThreshold){
                        Write-Host "- Adding to results (Secret Expires: $opDays Days)." -ForegroundColor Yellow
                        $secretObj = [pscustomobject] @{
                            AppName = $app.DisplayName
                            AppId = $app.AppId
                            SecretStartDate = $s.StartDate
                            SecretEndDate = $s.EndDate
                            SecretExpiryDays = $opDays
                            CertStartDate = "---"
                            CertEndDate = "---"
                            CertExpiryDays = "---"
                            Owner = $appOwnerUN
                        }
                        $resultObj += $secretObj # Add test results to result object.
                    }
                }

                # Loop each certificate and compare end date.
                ForEach($c in $certs){
                    $operation = ($c.EndDate - $now)
                    [int]$opDays = $operation.Days
                    if($opDays -le $daysThreshold){
                        Write-Host "- Adding to results (Cert Expires: $opDays Days)." -ForegroundColor Yellow
                        $certObj = [pscustomobject] @{
                            AppName = $app.DisplayName
                            AppId = $app.AppId
                            SecretStartDate = "---"
                            SecretEndDate = "---"
                            SecretExpiryDays = "---"
                            CertStartDate = $c.StartDate
                            CertEndDate = $c.EndDate
                            CertExpiryDays = $opDays
                            Owner = $appOwnerUN
                        }
                        $resultObj += $certObj # Add test results to result object.
                    }
                }
            }
        }
        Catch{
            $err = $_.Exception.Message
            Write-Host "WARNING: Failed to obtain application secrets. $err" -ForegroundColor Yellow
        }
    }
    Return $resultObj
}

### Main ###
if(!($daysThreshold)){
    $daysThreshold = 31
}

# Variables
[boolean]$alreadyExpired = $false
$reqModules = @('AzureADPreview')
[string]$logPath = "C:\Temp\AzureAD_EntApps_ExpiryDue_$(Get-Date -Format "yyyyMMdd").log"
[string]$exportPath = "C:\Temp\AzureAD_EntApps_ExpiryDue_$(Get-Date -Format "yyyyMMdd").csv"
[DateTime]$now = Get-Date
$Applications = $null

# Check required modules and import them.
Check-Modules

# Logging for diagnostic purposes. 
Start-Transcript -Path $logPath -Force

# Check connection to Azure.
$session = Get-AzureADConnection
Write-Host "INFO: Checking for applications expiring in $daysThreshold days..." -ForegroundColor Yellow
if($session){
    # Collect list of registered applications. 
    Write-Host "INFO: Getting applications list..."
    $Applications = Get-AzureADApplication -all $true
    $results = Get-AzAppExpiry
    $results | ft

    # Export result to CSV.
    Write-Host "INFO: Exporting CSV to: $exportPath" -ForegroundColor Yellow
    $results | Export-Csv -Path $exportPath -Force -NoTypeInformation
    Write-Host "COMPLETE!" -ForegroundColor Yellow
}
Stop-Transcript
# END

