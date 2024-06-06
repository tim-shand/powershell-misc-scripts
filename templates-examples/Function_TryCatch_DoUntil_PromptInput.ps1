<#

Function: Prompt user for Yes/No to install modules. 

#>

function Check-Modules {
    $moduleList = @('AzureAD')
    ForEach($m in $moduleList){
        if(!(Get-Module -ListAvailable -Name $m)){
            Try{
                Write-Host -ForegroundColor Yellow "[WARN]: Required module '$($m)' is missing."
                
                Do{
                    [string]$confirmModule = (Read-Host -Prompt "Proceed with installation of missing module (Y/N)")
                }
                Until(
                    $confirmModule -in ('y','Y','Yes','yes','N','n','No')
                )
                Write-Host "[INFO]: Installing module '$($m)'..." -NoNewline
                Install-Module -Name $m -Scope CurrentUser -Force -Confirm $false
                Write-Host -ForegroundColor Green "Complete!"
            } Catch{
                $err = $_.Exception.Message
                Write-Host -ForegroundColor Magenta "[ERROR]: Failed to install module '$($m)'. $err"
            }
        } else{
            Write-Host "[INFO]: Required module '$($m)' is already installed."
        }
    } 
}