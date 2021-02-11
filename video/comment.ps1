<#
	.SYNOPSIS
		Download Bilibili comments and replies.
	.DESCRIPTION
		Relies on the official API. 
	.PARAMETER CommentsPerPage
		Specifies the number of comments contained in one jsson file. Defaults to the maximum value of 49.
		Corresponds to 'pn' in the official API.
	.PARAMETER Oid
		Specifies the ID of the object-of-interest.
	.PARAMETER Path
		Specifies the folder in which the 'comments' folder will be saved.
	.PARAMETER Type
		Specifies the type of the object-of-interest. Refer to the readme file for a list of allowed values.
	.PARAMETER Mode
		Specifies which sorting method should be used. Refer to the readme file for more info.
	.PARAMETER ReplyPageLimit
		Specifies the limit for the number of pages of replies. Set this to 0 if you don't want additional
		pages of replies.
	.PARAMETER Interval
		Specifies the interval between each web request.
	.INPUTS
		None
	.OUTPUTS
		<Path>\comments\
		<Path>\comments\page<pn>.json
		...
		<Path>\comments\page<pn>_replies\
		...
		<Path>\comments\page<pn>_replies\<rpid>_page<pn>.json
		...
		<Path>\comments\metadata.json (if -SaveMetadata is specified)
	.LINK
		https://api.bilibili.com/x/v2/reply?jsonp=jsonp&pn=1&type=1&oid=170001&sort=2&ps=49
		https://api.bilibili.com/x/v2/reply/reply?jsonp=jsonp&pn=1&type=1&oid=170001&sort=2&ps=49&root=1796347201
#>

[CmdletBinding()]
param (
	[ValidateRange(1,49)][int]$CommentsPerPage=49,
	[ValidateRange(1,20)][int]$RepliesPerPage=20,
	[Parameter(Mandatory,Position=0)][ValidateRange("Positive")][int]$Oid,
	[ValidateScript({Test-Path -LiteralPath $_}, ErrorMessage="The specified directory does not exist.")][String]$Path=".",
	[ValidateRange("Positive")][int]$Type=1,
	[ValidateRange(0,2)][int]$Mode=0,
	[ValidateRange("NonNegative")][int]$ReplyPageLimit=[int]::MaxValue, #0: no additional pages
	[ValidateRange("Positive")][int]$CommentPageLimit=[int]::MaxValue,
	[ValidateRange("NonNegative")][int]$Interval=0,
	[switch]$NoMetadata
)

$DebugPreference="Inquire"

$CachedDirState=$False #reduces disk access
$BaseParams=@{
	"type"=$Type
	"oid"=$Oid
	"mode"=$Mode
}

function Get-WebJson {
	param (
		[Parameter(Mandatory)][int]$Next,
		[String]$Root
	)
	
	$IsComment=$Root -eq ""
	(Invoke-WebRequest "https://api.bilibili.com/x/v2/reply/$(if($IsComment){'main'}else{'detail'})" -Body (
		$BaseParams+
		(@{"next"=$Next})+
		$(if ($IsComment) {
			@{"ps"=$CommentPageLimit}
		} else {
			@{"ps"=$ReplyPageLimit;"root"=$Root}
		})
	)).Content
	
	if ($Interval -ne 0) {
		Write-Verbose "Start sleeping for $Interval second(s)"
		Start-Sleep $Interval
	}
}

if ($ReplyPageLimit -eq 0) {
	Write-Warning "Collapsed replies are ignored"
}

if (!$NoMetadata) {
	Write-Host "Saving metadata..."
	@{
		"oid"=$Oid
		"type"=$Type
		"comments_per_page"=$CommentsPerPage
		"replies_per_page"=$RepliesPerPage
		"sort"=$Mode
		"comment_page_limit"=$CommentPageLimit
		"reply_page_limit"=$ReplyPageLimit
	}|ConvertTo-Json|Out-File -LiteralPath (Join-Path $Path "metadata.json")
}

$NextId=0
while (++$i) {
	if ($i -gt $CommentPageLimit) {
		break
	}
	
	$Json=(Get-WebJson -Next $NextId)
	$JsonObject=$Json|ConvertFrom-Json
	
	if ($JsonObject.code -ne 0) {
		Throw "The server returned an error: "+$JsonObject.message
	}

	if (($JsonObject.data.cursor.is_end -eq $null) -or $JsonObject.data.cursor.is_end) {
		break
	}
	
	$NextId=$JsonObject.data.cursor.next
	
	Write-Host "Saving page $i..."
	$Json|Out-File -LiteralPath (Join-Path $Path "page$i.json")
	
	if ($ReplyPageLimit -eq 0) {
		continue
	}
	
	Write-Host "Saving replies for page $i..."
	foreach ($Comment in $JsonObject.data.replies) {
		if ($Comment.rcount -eq $Comment.replies.Length) {
			continue
		}
		
		if (!$CachedDirState) { 
			New-Item -ItemType Directory -Force -Path (Join-Path $Path "page${i}_replies")|Out-Null #putting this in the for loop avoids the creation of empty folders
			$CachedDirState=$True
		}

		$RNextId=0
		$j=0
		while (++$j) {
			if ($j -gt $ReplyPageLimit) {
				break
			}
			
			$RJson=Get-WebJson -Next $RNextId -root $Rpid
			$RJsonObject=$RJson|ConvertFrom-Json
			
			if ($RJsonObject.code -ne 0) {
				Throw "The server returned an error: "+$RJsonObject.message
			}
			
			if (($RJsonObject.data.cursor.is_end -eq $null) -or $RJsonObject.data.cursor.is_end) {
				break
			}
			
			$RNextId=$RJsonObject.data.cursor.next
			
			$Rpid=$Comment.rpid
			Write-Host "Saving replies for comment @ rpid=$Rpid"
			$RJson|Out-File -LiteralPath (Join-Path $Path "page${i}_replies" "${Rpid}_page$j.json")
		}
	}
	$CachedDirState=$false
}

Write-Host "Done!"