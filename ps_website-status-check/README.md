# Powershell: Website Status Check
- Perfoms basic website check for status and keyword search using Powershell.   
- Writes results to event log for monitoring system detection.   

# Usage
```
> .\PS-WebsiteCheck.ps1 -url https://google.com -SearchString "Google" -workingDir C:\temp
```

### Inputs
- URL : *_Website address (requires full HTTPS://)._*  
- SearchString : *_String of text that the script will look for in the websites code._*  
- WorkingDir : *_Location to store output file and downloaded website file._*   
   
### Outputs
- Writes results to terminal and to Windows Event Log.   
