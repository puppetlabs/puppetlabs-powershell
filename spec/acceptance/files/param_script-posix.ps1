Param(
	[String] $CommandName,
	[String] $fileOut
)
$cmd = Get-Command -Name $CommandName
New-Item $fileOut -ItemType File
$cmd | Out-File $fileOut -Encoding ASCII
