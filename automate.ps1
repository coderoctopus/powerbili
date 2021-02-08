param (
	[Parameter(Mandatory,Position=0)][ValidateScript({Test-Path $_}, ErrorMessage="The specified file does not exist.")][string]$File
)

$Content=Get-Content $File
foreach ($Line in $Content) {
	if ($Line -eq "") {
		continue
	}
	& $PSScriptRoot\video_shortcut.ps1 $Line -Path "dec"
}
