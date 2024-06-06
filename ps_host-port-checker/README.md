# Powershell: Host Port Checker
*_Powershell: Check specified port access/availability on target hosts._*    

# Usage
```
> .\ps_host-port-checker.ps1 -hosts 10.0.10.1,ts-core-rt01 -ports 22,80,443
> .\ps_host-port-checker.ps1 -hosts 10.0.10.50 -ports 22,80,443 -exportCSV $true -outfile 'C:\temp\results.csv'
```

### Inputs
- Hosts
  - IPaddress or hostname (separated by ',').
- Ports
  - List of ports to check (separated by ','). 
   
### Outputs
- Output to terminal.
- CSV export.
