# Powershell: Azure (Entra ID) - Entra ID Enterprise Apps Expiring
*_Generate CSV output of due to expire application service principals in Entra ID._*

- Requires 'AzureAD Preview' Module (`Install-Module AzureADPreview`).   
- Defaults to 31 days threshold, unless value is provided (-daysThreshold).   

# Usage
## Execute from terminal:
```
.\ps_az-entra-entapps-expiring.ps1 -daysThreshold 31
```

## Outputs
- CSV File: `AzureAD_EntApps_ExpiryDue_<Date>.csv.`
- Transcript:  `AzureAD_EntApps_ExpiryDue_20240703.log`
