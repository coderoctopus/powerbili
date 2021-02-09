[CmdletBinding()]
param (
	[ValidateRange(1,20)][int]$ItemsPerPlaylist=20,
	[Parameter(Position=0)][ValidateRange("Positive")][int]$MediaId=1112724373,
	[Parameter(Mandatory)][ValidateScript({Test-Path $_}, ErrorMessage="The specified directory does not exist.")][string]$Path
)

$DebugPreference="Inquire"

function Get-WebJson {
	param (
		[Parameter(Position=0)][ValidateRange("Positive")][int]$Pn
	)
	
	$QuereyParams=@{
		"media_id"=$MediId
		"pn"=$Pn
		"ps"=$ItemsPerPlaylist
		"order"="mtime"
		"type"="0"
		"tid"="0"
	}
	(Invoke-WebRequest "https://api.bilibili.com/x/v3/fav/resource/list" -Body $QuereyParams).Content
}

$result=""

for ($($i=1;$HasNext=$true);$HasNext;++$i) {
	$Json=(Get-WebJson $i)|jq '{"bvids": [.data.medias[].bvid],"has_next": .data.has_more}'
	#Write-Debug "$Json"
	$HasNext=[System.Convert]::ToBoolean(($Json|jq ".has_next"))
	$result+=($Json|jq "[.bvids[]]")
}

foreach ($bvid in ($result|jq ".[]" -r)) {
	bilili "https://www.bilibili.com/video/$bvid" -d $Path
}
