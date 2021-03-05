function Convert-IDType {
	<#
		.SYNOPSIS
			Convert bvid to aid and vice versa.
		.DESCRIPTION
			Relies on the official API. Keep in mind that the parameters are NOT validated,
			so make sure you validate them before calling the function.
		.PARAMETER aid
			Must be an integer.
		.PARAMETER Raw
			Returns raw json data instead of aid/bvid values.
		.EXAMPLE
			PS C:\> Convert-IDType BV17x411w7KC
			170001
		.EXAMPLE
			PS C:\> Convert-IDType 170001
			BV17x411w7KC
		.LINK
			https://api.bilibili.com/x/web-interface/view?aid=170001
			https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/video/info.md
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ParameterSetName="aid",Position=0)][int]$aid,
		[Parameter(Mandatory,ParameterSetName="bvid",Position=0)][String]$bvid,
		[switch]$Raw
	)
	
	$ParamName=$PSCmdlet.ParameterSetName
	$Json=(Invoke-WebRequest "https://api.bilibili.com/x/web-interface/view" -Body @{$ParamName=Get-Variable $ParamName -ValueOnly}).Content
	if ($Raw) {
		return $Json
	}
	
	$JsonObject=$Json|ConvertFrom-Json
	if ($JsonObject.code -eq 0) {
		return $JsonObject.data|Select -ExpandProperty ("aidbvid" -replace $ParamName,"")
	}
	
	Write-Error ("The server returned an error: "+$JsonObject.message+", trying an alternative API")
	$Json=(Invoke-WebRequest "https://api.bilibili.com/x/web-interface/archive/stat" -Body @{$ParamName=Get-Variable $ParamName -ValueOnly}).Content
	
	$JsonObject=$Json|ConvertFrom-Json
	if ($JsonObject.code -eq 0) {
		return $JsonObject.data|Select -ExpandProperty ("aidbvid" -replace $ParamName,"")
	}
	
	Throw ("The server returned an error: "+$JsonObject.message)
}

#[ValidateScript({($_ -cmatch "BV[1-9A-HJ-NP-Za-km-z]{10}") -or ([int]$_ -gt 0)}, ErrorMessage="Invalid aid or bvid.")][Parameter(Mandatory,Position=0)]$id,