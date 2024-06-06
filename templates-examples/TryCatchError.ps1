<#

Error Variable use within a Try/Catch scenario. 

#>


Try{
    Do-Thing
}
Catch{
    $err = $_.Exception.Message
    $message = "ERROR: Failed to perform the action.`r`n$err"
    Write-Host -ForegroundColor Yellow ($message) #| Out-File -FilePath $logfile -Append

}
