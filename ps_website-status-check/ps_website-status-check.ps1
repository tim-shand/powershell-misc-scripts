<#
.Synopsis
   Perfoms basic website check for status and keyword search.
.DESCRIPTION
   Perfoms basic website check for status and saves file for keyword search. 
   Write results to event log for monitoring detection. 
.EXAMPLE
   .\PS-WebsiteCheck.ps1 -url https://google.com -SearchString "Google" -workingDir C:\temp
.INPUTS
   URL - Website address (requires full HTTPS://).
   SearchString - String of text that the script will look for in the websites code.
   WorkingDir - Location to store output file and downloaded website file.
.OUTPUTS
   Writes results to terminal and to Windows Event Log. 
#>

param(
  [string]$url,
  [string]$SearchString,
  [string]$workingDir
)

function Get-WebsiteStatus{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,mandatory=$true)]
        [string] $url,
        [Parameter(Position=1,mandatory=$true)]
        [string] $searchString,
        [Parameter(Position=2,mandatory=$true)]
        [string] $workingDir
    )        
    process {
        $eventId_Info = 900
        $eventId_Warn = 901
        $eventId_Error = 902
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $request = [System.Net.WebRequest]::Create($url)
        $httpResponse = $request.GetResponse()
        $statusCode = [int]$httpResponse.StatusCode
        
        if($statusCode -eq 200){ # Website returns 'OK' (200).
            # Download website for string matching. 
            Try{
                Write-Host "Website: $url`r`nStatusCode: $statusCode" -ForegroundColor Yellow
                Write-Host "Downloading website as file for search string check..."
                $siteFile = New-Object System.Net.Webclient
                $siteFile.downloadfile($url,"$workingDir\webpage.txt")
                if(Test-Path -Path "$workingDir\webpage.txt"){
                    Write-Host "Download complete. Checking file..."
                    if(Get-Content -Path "$workingDir\webpage.txt" | Select-String -SimpleMatch $searchString -Quiet){
                        $msg = "INFO: Website ($url) is active. Search string '$searchString' found."
                        Write-Host $msg -ForegroundColor Green
                        Write-EventLog –LogName Application –Source $eventSource –EntryType Information –EventID $eventId_Info –Message $msg
                    } else{
                        $msg = "WARN: Website ($url) is active. Search string '$searchString' not found. Please check site has not changed."
                        Write-Host $msg -ForegroundColor Yellow
                        Write-EventLog –LogName Application –Source $eventSource –EntryType Warning –EventID $eventId_Warn –Message $msg
                    }
                    Remove-Item "$workingDir\webpage.txt" -Force -ErrorAction SilentlyContinue              
                } else{
                    Write-Host "WARN: Website file not found! May have failed to download." -ForegroundColor Yellow
                    Write-EventLog –LogName Application –Source $eventSource –EntryType Warning –EventID $eventId_Warn –Message $msg
                }                                
            }
            Catch{
                $err = $_.Exception.Message
                $msg = "ERROR: Failed to download website ($url) as file. $err"
                Write-Host $msg -ForegroundColor Red
                Write-EventLog –LogName Application –Source $eventSource –EntryType Error –EventID $eventId_Error –Message $msg
            }
        } else{ # Website returns anything else other than 200.
            $msg = "ERROR: Website ($url) returned bad status ($statusCode)."
            Write-Host $msg -ForegroundColor Red
            Write-EventLog –LogName Application –Source $eventSource –EntryType Error –EventID $eventId_Error –Message $msg
        }
    }
}

### Main ###
[string]$eventSource = "WebsiteStatusCheck"
New-EventLog –LogName Application –Source $eventSource -ErrorAction SilentlyContinue
Get-WebsiteStatus -url $url -searchString $SearchString -workingDir $workingDir
#Get-WebsiteStatus -url google.com -searchString Google -workingDir C:\temp

# EOF
