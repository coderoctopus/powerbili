<#
	.SYNOPSIS
		Executes a command in an automated fashion.
#>

param (
	[Parameter(Mandatory,Position=0)][string]$Command,
	[Parameter(Mandatory,Position=1)][ValidateScript({Test-Path $_ -PathType leaf}, ErrorMessage="The specified file does not exist.")][string]$File
)

$DebugPreference="Inquire"

$Content=Get-Content $File
foreach ($Line in $Content) {
	if ($Line -eq "") {
		continue
	}
	Invoke-Expression $Command
	Write-Debug "pause"
}
