$temp = "C:/temp"
if(!(Test-Path $temp)){
    mkdir $temp
}
Get-Service WinRM | Export-Csv "$temp\services.csv"
