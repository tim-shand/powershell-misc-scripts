<#
.SYNOPSIS: 
Use LogInsight API to get current license count. Send results in email to specified address.  

.INPUTS: 
Parameter 1: 'workingDir' = Working directory for storing log file. 
Parameter 2: 'serverDNS' = The DNS name of the server (syslog).  
Parameter 3: 'un' = The username for connecting to LogInsight.  

.OUTPUTS: 
Writes results to event log for record keeping.

.REVISION: 
1.0  Initial release 

.CONTRIBUTORS: 
Tim Shand :: 06-05-2022 :: Initial version 
#> 
param(
    [string]$workingDir = "C:\CCL\PV2Working",
    [string]$serverDNS = "syslog.services.concepts.co.nz",
    [string]$un = "ccl-api-licensing",
    [string]$aesKeyFile = "$workingDir\li-cred.key",
    [string]$pwdFile = "$workingDir\li-cred.pwd"
)
# Setup Logging
$logFile = $workingDir + "\LogInsightLicense.log"
if(Test-Path $logFile){
    Remove-Item -Path $logFile -Force
}

# Create event log source, skip if already exists. 
$EventSource = "PulseV2-LogInsightLicenseCheck" #Event log source name
New-EventLog –LogName Application –Source $EventSource -ErrorAction SilentlyContinue

# Create AES Encryption Key. Store the AESKey into a file.
# Uncomment block to create new key/password pair. 
<#
$AESKey = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
Set-Content $aesKeyFile $AESKey
$pw = Read-Host "Enter Password" -AsSecureString | ConvertFrom-SecureString -Key $AESKey
Add-Content $pwdFile $pw
#>

# Read in credential file, decrypt password.
$securePwd = Get-Content $pwdFile | ConvertTo-SecureString -Key $(Get-Content $aesKeyFile)
$credObject = New-Object System.Management.Automation.PSCredential -ArgumentList $un, $securePwd
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePwd)
$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Connect to API, get session token. 
Try{
    $apiBaseURL = "https://$($serverDNS):9543/api/v1"
    $apiConnStr = @{"username"="$un";"password"="$pw";"provider"="Local"}
    $apiConn = @(Invoke-RestMethod -Method POST -ContentType application/json -Body (ConvertTo-JSON $apiConnStr) -Uri "$apiBaseURL/sessions")
    $apiSessionId = $apiConn.sessionId
} Catch{
    $err = $_.Exception.Message
    $message = "ERROR: Failed to connect to LogInsight API. $err"
    Write-Output($message) | Out-File -FilePath $logfile -Append
    Write-EventLog –LogName Application –Source $EventSource –EntryType Error –EventID 750 –Message ($message)
    #Exit
}

# Run Checks
if($apiSessionId -ne $NULL){
    # Licensing
    Try{
        $apiLicenseStr = @{"Authorization"=" Bearer $apiSessionId"}
        $apiLicense = @(Invoke-RestMethod -Method GET -ContentType application/json -Headers $apiLicenseStr -Uri "$apiBaseURL/licenses")
    } Catch{
        $err = $_.Exception.Message
        $message = "ERROR: Failed to obtain API license data. $err"
        Write-Output($message) | Out-File -FilePath $logfile -Append
        Write-EventLog –LogName Application –Source $EventSource –EntryType Error –EventID 750 –Message ($message)
    }

    # Version
    Try{
        $apiVersionStr = @{"Authorization"=" Bearer $apiSessionId"}
        $apiVersion = @(Invoke-RestMethod -Method GET -ContentType application/json -Headers $apiVersionStr -Uri "$apiBaseURL/version")
    } Catch{
        $err = $_.Exception.Message
        $message = "ERROR: Failed to obtain API version data. $err"
        Write-Output($message) | Out-File -FilePath $logfile -Append
        Write-EventLog –LogName Application –Source $EventSource –EntryType Error –EventID 750 –Message ($message)
    }

    # Write Results to File / Event Log
    $message = ("VMware LogInsight License Report: 
    Host: $serverDNS
    LicenseStatus: $($apiLicense.licenses.status)
    LicenseConf: $($apiLicense.licenses.configuration)
    LicenseMax: $($apiLicense.maxOsis)
    LicenseCount: $($apiLicense.averageOsiUsage)
    Release: $($apiVersion.releaseName)
    Version: $($apiVersion.version)
    ")
    Write-Output($message) | Out-File -FilePath $logfile -Append
    Write-EventLog –LogName Application –Source $EventSource –EntryType Information –EventID 750 –Message ($message)
} else{
    $message = "ERROR: API connection failed. Abort. $err"
    Write-Output($message) | Out-File -FilePath $logfile -Append
    Write-EventLog –LogName Application –Source $EventSource –EntryType Error –EventID 750 –Message ($message)
}

