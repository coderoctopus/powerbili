#shortcut to saving (ideally) all info related to an uploader

[CmdletBinding()]
param (
	[ValidateRange("Positive")][Parameter(Mandatory,ParameterSetName="aid",Position=0)][int]$Uid,
	[ValidateScript({Test-Path -LiteralPath $_}, ErrorMessage="The specified directory does not exist.")][string]$Path="." #dir for all uploaders
	[switch]$NoStats,
	[switch]$NoCommunity #does nothing if all switches are on
)

$UploaderPath = Join-Path $Path $Uid
New-Item -ItemType Directory -Force -Path $UploaderPath|Out-Null

if (!$NoStats) {
	Write-Host "Saving uploader statistics..."
	(Invoke-WebRequest "https://api.bilibili.com/x/space/upstat?mid=$Uid&jsonp=jsonp").Content|Out-File -LiteralPath (Join-Path $UploaderPath "stats.json")
	(Invoke-WebRequest "https://api.bilibili.com/x/relation/stat?vmid=$Uid&jsonp=jsonp").Content|Out-File -LiteralPath (Join-Path $UploaderPath "stats2.json")
}

if (!$NoCommunity) {
	Write-Host "Saving community posts..."
	& $PSScriptRoot\community.ps1 $Uid -Path (Join-Path $UploaderPath "community")
}