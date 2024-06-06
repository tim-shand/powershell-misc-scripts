<#
.Synopsis
   Check port status for target hosts. 
.EXAMPLE
    .\Network-CheckPortsByArray.ps1 -hosts 10.0.10.1,ts-core-rt01 -ports 22,80,443
    .\Network-CheckPortsByArray.ps1 -hosts 10.0.10.1,ts-core-rt01 -ports 22,80,443 -exportCSV $true -outfile 'C:\temp\Get-HostsPortStatus.csv'
.INPUTS
   Hosts - IPaddress or hostname (separated by ',').
   Ports - List of ports to check (separated by ','). 
.OUTPUTS
   Terminal output. OPTIONAL: CSV export.  
#>

param(
    [String[]]$hosts,
    [string[]]$ports,
    [bool]$exportCSV = $false,
    [string]$outfile = 'C:\temp\Get-HostsPortStatus.csv'
)

function Get-HostsPortStatus ($hosts, $ports, $exportCSV, $outfile){   
    $resultObj = @() # Create object to contain results. 
    ForEach($h in $hosts){ # Loop through each host.
        ForEach($p in $ports){ # Loop tyrhrough each port.
            $connTest = (Test-NetConnection -ComputerName $h -port $p -ErrorAction SilentlyContinue)
            $connObj = [pscustomobject] @{
                Host = $h
                IPAddress = $connTest.RemoteAddress
                Port = $p
                Ping = $connTest.PingSucceeded
                Result = $connTest.TcpTestSucceeded
            }
            $resultObj += $connObj # Add test results to result object. 
        }
    }
    return $resultObj | format-table
    if($exportCSV){
        $resultObj | Export-CSV -Path $outfile -NoTypeInformation
    }
}

### Main ###
Get-HostsPortStatus -hosts $hosts -ports $ports
#EOF
