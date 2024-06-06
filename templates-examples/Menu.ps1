<#
.Synopsis
   List 
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
#>

### Functions ###

function Task1 {
    Write-Host "Performing task 1..." -ForegroundColor Green
    return
}

function Task2 {
    Write-Host "Performing task 2..." -ForegroundColor Cyan
    return
}

function MainMenu { # Main Menu
    clear    
    while($menu -ne 3){
        Try{
            Write-Host "`r`n---------------------" -ForegroundColor Yellow
            Write-Host "### Menu Template ###" -ForegroundColor Yellow
            Write-Host "---------------------" -ForegroundColor Yellow
            Write-Host "`r`nPlease select a task from the menu: `n" -ForegroundColor Green
            Write-Host "1. Task 1.`n2. Task 2.`n3. Exit`n"
            $menu = (Read-Host -Prompt "Please select a task number" -ErrorAction SilentlyContinue)
            if($menu -notin (1,2,3)){
                Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
            }
            switch ($menu) {
                1 {Task1}
                2 {Task2}
                3 {Write-Host "Exiting...`n`r" -ForegroundColor Yellow}
            }
        }
        Catch{
            Write-Host "Invalid selection, please try again.`n" -ForegroundColor Yellow
        }
    }
}

##### Main #####
MainMenu
