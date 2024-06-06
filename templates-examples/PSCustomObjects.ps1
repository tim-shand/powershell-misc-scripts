### PS Custom Objects ###

# Example 1
$customObj01 = [pscustomobject] @{
    ID = "12345"
    VRF = "1q2w3e"
    Address = "Test"
}
$customObj01


# Example 2
$objectCollection=@()
$object = New-Object PSObject
Add-Member -InputObject $object -MemberType NoteProperty -Name Path -Value ""
Add-Member -InputObject $object -MemberType NoteProperty -Name LastWrite -Value ""

$groups | ForEach-Object {
	$groupCurrent = $_
	$users | ForEach-Object {
		$userCurrent = $_
   		$object.Group = $groupCurrent
		$object.User = $userCurrent
		$objectCollection += $object
	}
}
$objectCollection

# Example 3
[array]$serverList = @(
    'RVIWPDARM-COL2',
    'RVIWPDCA01',
    'RVIWPDCRMSQL01',
    'RVIWPDCRMWEB01',
    'RVIWPDDC05',
    'RVIWPDDC06',
    'RVIWPDGIT01',
    'RVIWPDKMS02',
    'RVIWPDLMS1',
    'RVIWPDLTM01-A',
    'RVIWPDOMGW01',
    'RVIWPDSCOMGW01',
    'RVIWPDSCOMT',
    'RVIWPDSP13A01',
    'RVIWPDSP13SQL01',
    'RVIWPDSP13W01',
    'RVIWPDTITAN01',
    'RVNWPDComTS11',
    'RVRWPDSQL01',
    'RVRWPDVCMA01',
    'RVRWPDVJH04',
    'testio',
    'WPDNETCENTER1'
)

# Single layer
$resultObj = @()
ForEach($s in $serverList){
    $connTest = (Test-NetConnection -ComputerName $s -port 3389)
    $connObj = [pscustomobject] @{
        Server = $connTest.ComputerName
        IPAddress = $connTest.RemoteAddress
        Port = $connTest.RemotePort
        Result = $connTest.TcpTestSucceeded
    }
    $resultObj += $connObj
}
$resultObj | ft

# Mulitple layers (with function).
function Get-HostsPortStatus ($hosts, $ports, $exportCSV, $outfile){   
    $resultObj = @() # Create object to contain results. 
    ForEach($h in $hosts){ # Loop through each host.
        ForEach($p in $ports){ # Loop tyrhrough each port.
            $connTest = (Test-NetConnection -ComputerName $h -port $p -ErrorAction SilentlyContinue)
            $connObj = [pscustomobject] @{
                Host = $h
                IPAddress = $connTest.RemoteAddress
                Port = $connTest.RemotePort
                Ping = $connTest.PingSucceeded
                Result = $connTest.TcpTestSucceeded
            }
            $resultObj += $connObj # Add test results to result object. 
        }
    }
    return $resultObj | ft
    if($exportCSV){
        $resultObj | Export-CSV -Path $outfile -NoTypeInformation
    }
}
Get-HostsPortStatus -hosts $hosts -ports $ports