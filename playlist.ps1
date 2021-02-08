[CmdletBinding()]
param (
	[ValidateRange(1,20)][int]$ItemsPerPlaylist=20,
	[Parameter(Position=0)][ValidateRange("Positive")][int]$MediaId=1112724373,
	[Parameter(Mandatory)][ValidateScript({Test-Path $_}, ErrorMessage="The specified directory does not exist.")][string]$Path
)

$DebugPreference="Inquire"

function Get-JsonURL {
	param (
		[Parameter(Position=0)][ValidateRange("Positive")][int]$Pn
	)
	"https://api.bilibili.com/x/v3/fav/resource/list?media_id=$MediaId&pn=$pn&ps=$ItemsPerPlaylist&keyword=&order=mtime&type=0&tid=0&platform=web&jsonp=jsonp"
}

$result=""

for ($($i=1;$HasNext=$true);$HasNext;++$i) {
	$Json=(Invoke-WebRequest (Get-JsonURL $i)).Content|jq '{"bvids": [.data.medias[].bvid],"has_next": .data.has_more}'
	#Write-Debug "$Json"
	$HasNext=[System.Convert]::ToBoolean(($Json|jq ".has_next"))
	$result+=($Json|jq "[.bvids[]]")
	#(Invoke-WebRequest (Get-JsonURL $i)).Content
}

foreach ($bvid in ($result|jq ".[]" -r)) {
	bilili "https://www.bilibili.com/video/$bvid" -d $Path
}
