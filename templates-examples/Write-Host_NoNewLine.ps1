Write-Host "[$(Get-Date)] [PROCESS] Doing something..." -NoNewline
Try{
    #do something
    Write-Host " [DONE]"
}
Catch{
    $err = $_.Exception.Message
    Write-Host " [FAILED]"
}