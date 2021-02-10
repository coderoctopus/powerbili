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
	.PARAMETER Sort
		Specifies which sorting method should be used. Refer to the readme file for more info.
	.PARAMETER ReplyPageLimit
		Specifies the limit for the number of pages of replies. Set this to 0 if you don't want additional
		pages of replies.
	.PARAMETER HotCommentsBehavior
		Specifies whether and how to include hot comments in json files. Allowed values: 
			Always (Not recommended because the entry is the same across all files)
			Never (Default value, recommended if 'sort' is set to 2)
			FirstPage (Recommended if 'sort' is set to 0 or 1)
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
	[ValidateRange(0,2)][int]$Sort=2,
	[ValidateRange("NonNegative")][int]$ReplyPageLimit=[int]::MaxValue, #0: no additional pages
	[ValidateRange("Positive")][int]$CommentPageLimit=[int]::MaxValue,
	[ValidateRange("NonNegative")][int]$Interval=0,
	[ValidateSet("Always","FirstPage","Never")][String]$HotCommentsBehavior="Never",
	[switch]$SaveMetadata=$true
)

$DebugPreference="Inquire"

$CurrentPage=1
$CachedDirState=$False #reduces disk access
$BaseParams=@{
	"type"=$Type
	"oid"=$Oid
	"sort"=$Sort
}
enum Behavior {
	Always
	FirstPage
	Never
}
$HotParams=@{}
if ($HotCommentsBehavior -eq "Never") {
	$HotParams=@{"nohot"="1"}
}

function Get-WebJson {
	param (
		[Parameter(Mandatory)][int]$Pn,
		[String]$Root
	)
	
	$IsComment=$Root -eq ""
	(Invoke-WebRequest "https://api.bilibili.com/x/v2/$(if(!$IsComment){'reply/'})reply" -Body (
		$BaseParams+
		$HotParams+
		(@{"pn"=$Pn})+
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

function Out-Replies {
	param (
		[Parameter(ValueFromPipeline)][String]$Json
	)
	
	if ($ReplyPageLimit -eq 0) {
		return
	}
	
	Write-Host "Saving replies for page $CurrentPage..."
	$Comments=$Json|jq ".data.replies"
	for ($i=0; $i -lt ($Comments|jq "length"); ++$i) { #this avoids errors caused by mismatch between different counting methods. sometimes the server returns 48 objects despite claiming (in .data.page.size) there are 49
		$Comment=$Comments|jq ".[$i]"
		[int]$ReplyCount=$Comment|jq ".rcount"
		if ($ReplyCount -eq [int]($Comment|jq ".replies|length")) {
			continue
		}
		if (!$CachedDirState) { 
			New-Item -ItemType Directory -Force -Path (Join-Path $Path "page${CurrentPage}_replies")|Out-Null #putting this in the for loop avoids the creation of empty folders
			$CachedDirState=$True
		}
		$Rpid=$Comment|jq ".rpid"
		$ReplyPageCount=[Math]::Ceiling($ReplyCount/$RepliesPerPage)
		
		Write-Verbose "Comment @ rpid=$Rpid has $ReplyPageCount page(s) of replies, saving up to $ReplyPageLimit"
		for ($j=1; $j -le $(if ($ReplyPageCount -gt $ReplyPageLimit) {$ReplyPageLimit} else {$ReplyPageCount}); ++$j) {
			Get-WebJson -pn $j -root $rpid|Out-File -LiteralPath (Join-Path $Path "page${CurrentPage}_replies" "${Rpid}_page${j}.json")
		}
	}
	$CachedDirState=$false
}

if ($ReplyPageLimit -eq 0) {
	Write-Warning "Collapsed replies are ignored"
}

Write-Host "Calculating total number of pages..."
$Json=Get-WebJson -pn $CurrentPage
if ($HotCommentsBehavior -eq "FirstPage") {
	$HotParams=@{"nohot"="1"}
}

[int]$CommentPageCount=[Math]::Ceiling(($Json|jq ".data.page.count")/$CommentsPerPage)
Write-Host "Object @ oid=$Oid has $CommentPageCount page(s) of comments, saving up to $CommentPageLimit"

if ($CommentPageCount -le 0) {
	Throw "The object specified doesn't have any comments, or the server returned an error"
}

if ($SaveMetadata) {
	Write-Host "Saving metadata..."
	@{
		"oid"=$Oid
		"type"=$Type
		"comments_per_page"=$CommentsPerPage
		"replies_per_page"=$RepliesPerPage
		"sort"=$Sort
		"comment_page_limit"=$CommentPageLimit
		"reply_page_limit"=$ReplyPageLimit
	}|ConvertTo-Json|Out-File -LiteralPath (Join-Path $Path "metadata.json")
}

Write-Host "Saving page $CurrentPage..."
$Json|Out-File -LiteralPath (Join-Path $Path "page${currentPage}.json")
$Json|Out-Replies 

for ($i=2; $i -le $(if ($CommentPageCount -gt $CommentPageLimit) {$CommentPageLimit} else {$CommentPageCount}); ++$i) {
	$CurrentPage=$i
	$Json=Get-WebJson -pn $CurrentPage
	
	Write-Host "Saving page $CurrentPage..."
	$Json|Out-File -LiteralPath (Join-Path $Path "page${currentPage}.json")
	$Json|Out-Replies
}

Write-Host "All done."