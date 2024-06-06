# Powershell: LDAPS Port Check
*_Powershell: Test LDAP/S functionality and port connectivity to primary domain contoller (PDC)._*    

# Usage
Defaults to locahost if no PDC avilable (assumes non-domain joined, WORKGROUP).    
```
> .\LDAPS-Check.ps1 -dir C:\Temp
```

### Outputs
- File: LDAPS_Status_[Computer_Name].csv
