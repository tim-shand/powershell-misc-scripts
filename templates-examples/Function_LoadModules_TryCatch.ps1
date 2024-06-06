<#

Function: Load required modules with Try/Catch clause.

#>

# Function: Check required modules and import them. 
function Check-Modules {
    Write-Host -BackgroundColor Magenta "--- Checking/Importing Modules ---"
    $reqModules = @('AzureADPreview')
    [int]$mCount = 0
    ForEach($m in $reqModules){
        $currentModule = (Get-Module -Name $m -ListAvailable).Version
        if($currentModule){
            Try{
                Import-Module $m
                Write-Host "[INFO]: Successfully loaded module '$m'."
                $mCount += 1
            }
            Catch{
                $err = $_.Exception.Message
                Write-Host -ForegroundColor Red "[ERROR]: Failed to load module '$m'.`r`n$err"
                Break
            }
        } else{
            Write-Host -ForegroundColor Yellow "[WARNING]: Required module '$m' is not installed. Please install and try again."
            Break
        }
    }
    Write-Host -ForegroundColor Green "[INFO]: Successfully loaded $mCount/$($reqModules.Count) required modules."
}

# Main
Check-Modules