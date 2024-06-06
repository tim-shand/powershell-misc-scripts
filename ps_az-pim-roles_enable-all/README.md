# Powershell: Azure (Entra ID) - Enable all PIM Roles
*_Activate all Azure Entra ID PIM roles assigned to the authenticated user._*

- Requires 'AzureAD Preview' Module (`Install-Module AzureADPreview`).
- Requires a "reason" for enabling roles (auditing/logging). 

# Usage
## Example 1 - Manual execution:
```
> Check-Modules
> $session = Check-AzureSession
> Activate-PimRoles -session $session -reason "Some reason here."
```

## Example 2 - Execute from terminal:
```
.\Az-PIM-Roles_EnableAll.ps1 -reason "TESTING"
```
