#shortcut to saving (ideally) all info related to a VIDEO

[CmdletBinding()]
param (
	[ValidateRange("Positive")][Parameter(Mandatory,ParameterSetName="aid",Position=0)][int]$aid,
	[ValidatePattern("BV[1-9A-HJ-NP-Za-km-z]{10}",Options="None")][Parameter(Mandatory,ParameterSetName="bvid",Position=0)][string]$bvid,
	[ValidateScript({Test-Path $_}, ErrorMessage="The specified directory does not exist.")][string]$Path="." #dir for all videos
)

Import-Module $PSScriptRoot\..\modules\Convert-IDType.psm1, $PSScriptRoot\..\modules\Remove-IllegalChars.psm1

$Json=Convert-IDType (Get-Variable $PSCmdlet.ParameterSetName -ValueOnly) -Raw

if ($aid -eq 0) {
	$aid=[int]($Json|jq ".data.aid")
}
if ($bvid -eq "") {
	$bvid=$Json|jq ".data.bvid" -r
}

$VideoPath=(New-Item -ItemType Directory -Force -Path (Join-Path $Path ($Json|jq ".data.title" -r|Remove-IllegalChars))).FullName #dir for one video

Write-Host "Saving video statistics..."
$Json|Out-File (Join-Path $VideoPath "info.json")

Write-Host "Saving tag info..."
(Invoke-WebRequest "https://api.bilibili.com/x/web-interface/view/detail/tag?aid=$aid").Content|Out-File (Join-Path $VideoPath "tags.json")

Write-Host "Saving video description..."
(Invoke-WebRequest "https://api.bilibili.com/x/web-interface/archive/desc?&aid=$aid").Content|Out-File (Join-Path $VideoPath "description.json")

Write-Host "Saving episode info..."
(Invoke-WebRequest "https://api.bilibili.com/x/player/pagelist?aid=$aid").Content|Out-File (Join-Path $VideoPath "episodes.json")

Write-Host "Saving comments & replies..."
& $PSScriptRoot\comment.ps1 $aid -Path (New-Item -ItemType Directory -Force -Path (Join-Path $VideoPath "comments")).FullName

