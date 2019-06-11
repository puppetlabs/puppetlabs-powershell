$temp = "/tmp"
if(!(Test-Path $temp)){
    mkdir $temp
}
Get-Command -Name Get-Command | Export-Csv "$temp/commands.csv" -Encoding "ASCII"
