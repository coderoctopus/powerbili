function Remove-IllegalChars {
	<#
		.SYNOPSIS
			Replaces illegal characters in a file name.
		.DESCRIPTION
			ASCII control characters (0x00 to 0x1f) are simply removed from the name. Other
			illegal characters (e.g. pipe and quote) are replaced with their full-width counterparts.
		.EXAMPLE
			PS C:\> Remove-IllegalChars '"\/<>?*|:'
			＂＼／＜＞？＊｜：
			PS C:\> Remove-IllegalChars "Foo: Bar"
			Foo：Bar
			PS C:\> Remove-IllegalChars "Foo: Bar" -KeepSpace
			Foo： Bar
		.LINK
			https://docs.microsoft.com/en-us/dotnet/api/system.io.path.getinvalidfilenamechars?view=net-5.0
			https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline,Position=0)][AllowEmptyString()][String]$Name,
		[switch]$KeepSpace
	)
	
	if ($Name -eq "") {
		return "null"
	}
	
	$Chars=$Name.ToCharArray()
	$i=-1
	while ($true) {
		$i=$Name.IndexOfAny([IO.Path]::GetInvalidFileNameChars(),$i+1)
		if ($i -eq -1) {
			return $Chars -join ""
		}
		if ([int]$Chars[$i] -lt 32) {
			$Chars[$i]=$null
			continue
		}
		$Chars[$i]=[char]([int]$Chars[$i]+0xfee0) #converts to full width chars
		if ($KeepSpace) {
			continue
		}
		if (($i -gt $Chars.GetLowerBound(0)) -and ([int]$Chars[$i-1] -eq 32)) {
			$Chars[$i-1]=$null
		}
		if (($i -lt $Chars.GetUpperBound(0)) -and ([int]$Chars[$i+1] -eq 32)) {
			$Chars[$i+1]=$null
		}
	}
}