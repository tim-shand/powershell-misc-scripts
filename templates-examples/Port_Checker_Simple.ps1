### Simple port checker ###

$ports = @(1433, 445, 3389)
#$targets = @("CCLCHEUCAPV01","CCLCHEUCAPV02")
$targets = @("CCLCHSQL10")

$resultObj = @()
ForEach($t in $targets){

    ForEach($p in $ports){
        $r = (Test-NetConnection -ComputerName $t -Port $p)
        $result = [pscustomobject] @{
            Hostname = $r.ComputerName
            IPv4 = $r.RemoteAddress
            PortNum = $r.RemotePort
            PortResult = $r.TcpTestSucceeded
            Ping = $r.PingSucceeded
        }
        $resultObj += $result
    }
}
$resultObj | ft
