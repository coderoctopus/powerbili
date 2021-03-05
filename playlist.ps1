[CmdletBinding()]
param (
	[ValidateRange(1,20)][int]$ItemsPerPlaylist=20,
	[Parameter(Mandatory,Position=0)][ValidateRange("Positive")][int]$MediaId,
	[Parameter(Mandatory)][ValidateScript({Test-Path -LiteralPath $_}, ErrorMessage="The specified directory does not exist.")][string]$Path
)

$DebugPreference="Inquire"

$QueryParams=@{
	"media_id"=$MediaId
	"ps"=$ItemsPerPlaylist
	"order"="mtime"
	"type"="0"
	"tid"="0"
}

function Get-WebJson {
	param (
		[Parameter(Position=0)][ValidateRange("Positive")][int]$Pn
	)

	(Invoke-WebRequest "https://api.bilibili.com/x/v3/fav/resource/list" -Body ($QueryParams+@{"pn"=$Pn})).Content
}

$Result=@()
while (++$i) {
	$JsonObject=(Get-WebJson $i)|ConvertFrom-Json
	
	if ($JsonObject.code -ne 0) {
		Throw "The server returned an error: "+$JsonObject.message
	}
	
	foreach ($Item in $JsonObject.data.medias) {
		$Result+=[int]$Item.id
	}
	
	if (!$JsonObject.data.has_more) {
		break
	}
}

foreach ($aid in $Result) {
	& $PSScriptRoot\video\video-shortcut.ps1 $aid -Path $Path -OnErrorUseBiliPlus #bilili "https://www.bilibili.com/video/$bvid" -d $Path
	Write-Host "Start sleeping for 10 seconds..."
	Start-Sleep 10
}
