
$regPath = "HKLM:\System\currentcontrolset\services\kdc"
$dcs = Get-ADDomainController -filter * | Select Name,Hostname,IPv4Address,IsReadOnly,IsGlobalCatalog,OperatingSystem,Site | Sort-Object Name,Site
$resultObj = @()
ForEach($dc in $dcs){
    #Invoke-GPUpdate -Computer $dc.Hostname 
    #Invoke-Command -ComputerName $dc.Hostname -ScriptBlock{gpupdate /force}
    $dcObj = [pscustomobject] @{
        Server = $dc.Name
        Site = $dc.Site
        RegPathExist = (Invoke-Command -ComputerName $dc.Hostname -ScriptBlock{Test-Path -Path $Using:regPath})
        KrbtgtFullPacSignature = (Invoke-Command -ComputerName $dc.Hostname -ScriptBlock{
            if(Get-ItemPropertyValue -Path $Using:regPath -Name 'KrbtgtFullPacSignature' -ErrorAction SilentlyContinue){
                switch(Get-ItemPropertyValue -Path $Using:regPath -Name 'KrbtgtFullPacSignature' -ErrorAction SilentlyContinue){
                    0 {"0 - Disabled"}
                    1 {"1 – Default"}
                    2 {"2 - Audit Mode"}
                    3 {"3 - Enforcement Mode"}
                    default {"Not Set"}                
                }
            } else{
                "Not Set"
            }
        })
        LastGPUpdate = (Invoke-Command -ComputerName $dc.Hostname -ScriptBlock{
            $RegPath='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}'
            $LowTime=Get-ItemProperty -path $RegPath -name "EndTimeLo"
            $HighTime=Get-ItemProperty -path $RegPath -name "EndTimeHi"
            $CompTime=([long]$HighTime.EndTimeHi -shl 32) + [long] $LowTime.EndTimeLo
            [DateTime]::FromFileTime($CompTime).ToString("yyyy-MM-dd hh:mm:ss")
        })
    }
    $resultObj += $dcObj
}
$resultObj | ft
