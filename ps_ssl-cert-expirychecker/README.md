# Powershell: SSL Certificate Expiry Checker
- List installed SSL certificates due to expire in x days.  
- Write results of findings to Windows event log for detection by monitoring systems.   
- Excludes already expired certificates by default (optional).   

# Usage   
```
> .\PS-SSLCertificateExpiryCheck.ps1 -dir C:\temp -daysThreshold 9000 -EventLogging $True   
> .\PS-SSLCertificateExpiryCheck.ps1 -dir C:\temp -daysThreshold 30 -EventLogging $False   
> .\PS-SSLCertificateExpiryCheck.ps1 -dir C:\temp -daysThreshold 700 -EventLogging $True -sslOnly $false
```

### Inputs   
[string]$dir - *_Working directory for storing output log file._*   
[int]$daysThreshold - *_Number of days to check for SSL certificate 'NotAfter' datestamp._*    
[string]$scriptName - *_Used for log file naming._*     
[bool]$EventLogging - *_Enable writing to event log ($TRUE)._*    
[string]$EventSource - *_Event source name for event logging._*    
[int]$EventID - *_Event log ID to be used (requires $EventLog = $TRUE)._*    
[bool]$sslOnly - *_Optional switch, uses -SSLServerAuthentication._*    
   
### Outputs   
- Write results to event log for detection by monitoring system and also local log for script record.   
