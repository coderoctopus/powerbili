#shortcut to saving (ideally) all info related to a video
#todo: video downloader

[CmdletBinding()]
param (
	[ValidateRange("Positive")][Parameter(Mandatory,ParameterSetName="aid",Position=0)][int]$aid,
	[ValidatePattern("BV[1-9A-HJ-NP-Za-km-z]{10}",Options="None")][Parameter(Mandatory,ParameterSetName="bvid",Position=0)][string]$bvid,
	[ValidateScript({Test-Path -LiteralPath $_}, ErrorMessage="The specified directory does not exist.")][string]$Path=".",#dir for all videos
	[switch]$OnErrorUseBiliPlus, #SLOW
	[switch]$NoStats,
	[switch]$NoTags,
	[switch]$NoDescription,
	[switch]$NoEpInfo,
	[switch]$NoCommentsReplies #only creates a new dir if all switches are on
)

Import-Module $PSScriptRoot\..\modules\Convert-IDType.psm1, $PSScriptRoot\..\modules\Remove-IllegalChars.psm1, $PSScriptRoot\..\modules\New-UniqueEmptyDir.psm1

$DebugPreference="Inquire"

$Json=Convert-IDType (Get-Variable $PSCmdlet.ParameterSetName -ValueOnly) -Raw
$JsonObject=$Json|ConvertFrom-Json

$Title=""
$InfoFileName="info.json"
if ($JsonObject.code -eq 0) {
	if ($aid -eq 0) {
		$aid=$JsonObject.data.aid
	}
	$Title=$JsonObject.data.title
} else {
	if ($aid -eq 0) {
		Throw ("The server returned an error: "+$JsonObject.message+". Please try specifying AID instead of BVID so the script can skip the conversion and continue.")
	}
	
	if ($OnErrorUseBiliPlus) {
		Write-Warning ("The server returned an error: "+$JsonObject.message+", trying BiliPlus instead")
		$Json=[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding(28591).GetBytes((Invoke-WebRequest "https://www.biliplus.com/api/view?id=$aid").Content)) #biliplus returns charset="UTF-8" instead of charset=utf-8
		$JsonObject=$Json|ConvertFrom-Json
		
		if ($JsonObject.code -ne $null) {
			Write-Error ("BiliPlus server returned an error: "+$JsonObject.message+". Further queries will likely fail as well.")
		}
		
		$Title=$JsonObject.title
		$InfoFileName="info-biliplus.json"
	} else {
		Write-Error ("The server returned an error: "+$JsonObject.message+". Further queries may fail as well. To try to retrieve more info about this object, use the flag -OnErrorUseBiliPlus.")
	}
}

#$VideoPath=New-UniqueEmptyDir (Join-Path $Path ($Title|Remove-IllegalChars)) #todo: use this after incorporating the downloader
$RawDataPath=(Join-Path $Path ($Title|Remove-IllegalChars) "rawdata")

if (!$NoStats) {
	Write-Host "Saving video statistics..."
	$Json|Out-File -LiteralPath (Join-Path $RawDataPath $InfoFileName)
}

if (!$NoTags) {
	Write-Host "Saving tag info..."
	(Invoke-WebRequest "https://api.bilibili.com/x/web-interface/view/detail/tag?aid=$aid").Content|Out-File -LiteralPath (Join-Path $RawDataPath "tags.json")
}

if (!$NoDescription) {
	Write-Host "Saving video description..."
	(Invoke-WebRequest "https://api.bilibili.com/x/web-interface/archive/desc?&aid=$aid").Content|Out-File -LiteralPath (Join-Path $RawDataPath "description.json")
}

if (!$NoEpInfo) { 
	Write-Host "Saving episode info..."
	(Invoke-WebRequest "https://api.bilibili.com/x/player/pagelist?aid=$aid").Content|Out-File -LiteralPath (Join-Path $RawDataPath "episodes.json")
}

if (!$NoCommentsReplies) {
	Write-Host "Saving comments & replies..."
	try {
		& $PSScriptRoot\comment.ps1 $aid -Path (New-Item -ItemType Directory -Force -Path (Join-Path $RawDataPath "comments")).FullName
	} catch {
		Write-Error $Error[0]
	}
}
