#shortcut to saving (ideally) all info related to a VIDEO

[CmdletBinding()]
param (
	[ValidateRange("Positive")][Parameter(Mandatory,ParameterSetName="aid",Position=0)][int]$aid,
	[ValidatePattern("BV[1-9A-HJ-NP-Za-km-z]{10}",Options="None")][Parameter(Mandatory,ParameterSetName="bvid",Position=0)][string]$bvid,
	[ValidateScript({Test-Path $_}, ErrorMessage="The specified directory does not exist.")][string]$Path="." #dir for all videos
)

Import-Module $PSScriptRoot\avbv.psm1

Write-Host "Saving video statistics..."

$Json=Convert-IDType (Get-Variable $PSCmdlet.ParameterSetName -ValueOnly) -Raw

if ($aid -eq 0) {
	$aid=[int]($Json|jq ".data.aid")
}
if ($bvid -eq "") {
	$bvid=$Json|jq ".data.bvid" -r
}

$VideoPath=Join-Path $Path $bvid #dir for one video
New-Item -ItemType Directory -Force -Path $VideoPath|Out-Null

$Json|Out-File (Join-Path $VideoPath "stats.json")
& $PSScriptRoot\comment.ps1 $aid -Path $VideoPath -CommentPageLimit 1 -ReplyPagelimit 0

