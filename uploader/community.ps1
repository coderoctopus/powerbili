[CmdletBinding()]
param (
	[Parameter(Mandatory,Position=0)][ValidateRange("Positive")][int]$HostUid=319341196,
	[Parameter(Mandatory)][ValidateScript({Test-Path $_}, ErrorMessage="The specified directory does not exist.")][string]$Path
)

$DebugPreference="Inquire"

function Get-JsonURL {
	param (
		[Parameter(Position=0)][String]$Offset
	)
	"https://api.vc.bilibili.com/dynamic_svr/v1/dynamic_svr/space_history?host_uid=$HostUid&offset_dynamic_id=$Offset&need_top=1&platform=web"
}


for ($($i=0;$HasNext=$true;$NextOffset=0;$Raw="");$HasNext;++$i) {
	if ($Raw -ne "") {
		Write-Host "Saving page $i..." #A page is saved at the beginning of the next cycle, so the last page which always(?) contains nothing never gets saved
		$Raw|Out-File (Join-Path $Path "page$i.json")
	}
	$Raw=(Invoke-WebRequest (Get-JsonURL $NextOffset)).Content
	$Probe=$Raw|jq '{"has_next": .data.has_more,"length": (.data.cards|length)}'
	if (!($Raw.Substring($Raw.Length-50) -match '(?<="next_offset":).*?(?=,)')) { #Todo: drop jq. Jq can't currently handle huge numbers correctly. Why did they store large numbers as numbers in the first place though?
		Throw "Unexpected error: next_offset not found"
	}
	$HasNext=[int]($Probe|jq ".has_next")
	$NextOffset=$Matches[0]
}
