<#
.Synopsis
   List SSL certificates due to expire in x days. 
.DESCRIPTION   
   List SSL certificates due to expire in x days. Write results to event log for parsing or detection by monitoring software. 
   Exludes already expired certificates by default. 
.EXAMPLE
   .\PS-SSLCertificateExpiryCheck.ps1 -dir C:\temp -daysThreshold 9000 -EventLogging $True
   .\PS-SSLCertificateExpiryCheck.ps1 -dir C:\temp -daysThreshold 30 -EventLogging $False
   .\PS-SSLCertificateExpiryCheck.ps1 -dir C:\temp -daysThreshold 700 -EventLogging $True -sslOnly $false
.INPUTS
   Variable: daysThreshold - Number of days to check for SSL certificate 'NotAfter' datestamp. 
.OUTPUTS
   Write results to event log for detection by log parsing or RMM toolset and also local log for script record.  
.NOTES
   Includes optional event logging enable/disable. 
#>

# Input Parameters
param(
    [string]$dir, # Working directory.
    [int]$daysThreshold, # 30, Threshold in days for certificate expiry.
    [string]$scriptName , # "SSL-CertificateExpiryCheck",  Used for event source and log file naming. 
    [bool]$EventLogging = $TRUE, # Enable writing to event log. 
    [string]$EventSource = $scriptName, # Event source name for event logging. 
    [int]$EventID , # 999 Event log ID to be used (requires $EventLog = $TRUE).
    [bool]$sslOnly = $true # -SSLServerAuthentication switch
)

### Functions ###

function Get-ExpiringSSLCertificates ($dir, $daysThreshold, $EventLogging, $EventSource, $EventID) {
    $line = ""
    Get-ChildItem -Path cert:\* -SSLServerAuthentication:$sslOnly -Recurse | 
    Where-Object{ 
        ($_.NotAfter -lt ((Get-Date).AddDays($daysThreshold))) -and ($_.NotAfter -gt (Get-Date).AddDays(1)) -and 
        ($_.Issuer -notlike '*'+$env:ComputerName+'*') -and
	    ($_.Subject -notlike '*'+$env:ComputerName+'*') -and
        ($_.Issuer -ne 'CN=localhost') -and
        ($_.Issuer -notlike '*Microsoft*') -and
        
        ### !!! Extra lines to exclude certifiactes based on attributers can be placed here. ###
        ### !!! Below line is a template for adding exclusions.Remember to include the '-and' at the end ###        
        # Insert extra certificates below this line
        #($_.Issuer -notlike '*MS-Organization-P2P-Access*') -and
        #($_.Issuer -notlike '*MS-Organization-P2P-Access*') -and
		#($_.Issuer -notlike '*Windows Azure CRP Certificate Generator*') -and
        #($_.Issuer -notlike '*Broker-SSO*') -and
        #($_.Issuer -notlike '*Business Issuing CA*') -and
        # /End custom entries

		([bool]($_.PSobject.Properties.name -match "Thumbprint"))
        } |		
    Sort-Object NotAfter -Unique | ForEach-Object{
        $expiry = $_.NotAfter
        $expiry = $expiry.ToString('dd/MM/yyyy')
        $issuer = $_.Issuer
        $subject = $_.Subject
        $line = $line + ("Expiry: $expiry [Issuer: $issuer] [Subject: $subject]`r`n")
    }
    if($line -like "*Expiry*"){        
        $message = "The following certificates are due to expire within $daysThreshold days: `r`n" +$line
        if($EventLogging){
            Write-EventLog –LogName Application –Source $EventSource –EntryType Error –EventID $EventID –Message ($message)
        }
        Write-Output("$(Get-Date -format $df) :: WARN :: $message") | Out-File -FilePath $logfile -Append
        Write-Output $message 
    }	
	else{
        $message = "There are no certificates due to expire within $daysThreshold days."
        if($EventLogging){
            Write-EventLog –LogName Application –Source $EventSource –EntryType Information –EventID $EventID –Message ($message)
        }
        Write-Output("$(Get-Date -format $df) :: INFO :: $message") | Out-File -FilePath $logfile -Append
        Write-Output $message 
    }
}
### Main ###
$df = "yyyy-MM-dd HH:mm:ss" # Set date format
New-EventLog –LogName Application –Source $EventSource -ErrorAction SilentlyContinue # Create new event log source.

## Log file config, remove if larger than 5 MB. 
$logfile = ($dir + "\$scriptName.log")
If(Test-Path $logfile){
    $logfileSize = [math]::round((Get-ChildItem $logfile | Measure-Object -Property Length -Sum).Sum / 1MB,0)
    If($logfileSize -gt 5){
        Remove-Item $logfile -Force -ErrorAction SilentlyContinue

    }
}

Write-Output("`r`n$(Get-Date -format $df) :: START :: -----------------------") | Out-File -FilePath $logfile -Append
Write-Output("$(Get-Date -format $df) :: INFO :: Log path location: $logfile.") | Out-File -FilePath $logfile -Append
if($EventLogging){
    Write-Output("$(Get-Date -format $df) :: INFO :: Event logging is enabled.") | Out-File -FilePath $logfile -Append
}
Write-Output("$(Get-Date -format $df) :: INFO :: Certificate expiry threshold = $daysThreshold days.") | Out-File -FilePath $logfile -Append

## Set days if no value provides (testing purposes).
If(!$daysThreshold){
    $daysThreshold = 90
    Write-Output("$(Get-Date -format $df) :: INFO :: No value for days provided, default to $daysThreshold.") | Out-File -FilePath $logfile -Append
} Else{
    Write-Output("$(Get-Date -format $df) :: INFO :: Checking certificate due to expire in $daysThreshold days.") | Out-File -FilePath $logfile -Append
}
# Run certificate check function. 
Get-ExpiringSSLCertificates -dir $dir -daysThreshold $daysThreshold -EventSource $EventSource -EventID $EventID
Write-Output("$(Get-Date -format $df) :: END :: -----------------------") | Out-File -FilePath $logfile -Append
### EOF ###
