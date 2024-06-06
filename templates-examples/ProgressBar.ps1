### Powershell Progress Bar: In Loop ###
$i = 0 # Set progress bar counter.

$food = @('Pies', 'Salami', 'Fanta', 'Cheese', 'Hazy IPA', 'Olives')

ForEach($f in $food){
    $i = $i+1 # Increment the progress bar counter. 
    Write-Progress -Activity "Searching for food items..." -Status "Progress:" -PercentComplete ($i/($food).count*100)
    Start-Sleep -Milliseconds 250 # Add pause to delay progress ending to fast. Remove in prod. 
}