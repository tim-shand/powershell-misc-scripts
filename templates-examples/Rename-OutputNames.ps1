Get-WmiObject -Class win32_OperatingSystem -ComputerName $env:computername | `
Select @{N=’ComputerName’; E={$_.PSComputerName}}, @{N=’OS’; E={$_.caption}}, @{N=’SP’; E={$_.ServicePackMajorVersion}}

