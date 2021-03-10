[CmdletBinding()]
param (
	[ValidateRange(1,20)][int]$ItemsPerPlaylist=20,
	[Parameter(Mandatory,Position=0)][ValidateRange("Positive")][int]$MediaId
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

while (++$i) {
	$JsonObject=(Get-WebJson $i)|ConvertFrom-Json
	
	if ($JsonObject.code -ne 0) {
		Throw "The server returned an error: "+$JsonObject.message
	}
	
	foreach ($Item in $JsonObject.data.medias) {
		[int]$Item.id
	}
	
	if (!$JsonObject.data.has_more) {
		break
	}
}