function Remove-IllegalChars {
	<#
		.SYNOPSIS
			Replaces illegal characters in a file name.
		.DESCRIPTION
			ASCII control characters (0x00 to 0x1f) are replaced with spaces. Others
			(e.g. pipe and quote) are replaced with their full-width counterparts.
		.EXAMPLE
			PS C:\> Legalize-FileName '"\/<>?*|:'
			＂＼／＜＞？＊｜：
		.LINK
			https://docs.microsoft.com/en-us/dotnet/api/system.io.path.getinvalidfilenamechars?view=net-5.0
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline,Position=0)][ValidateNotNullOrEmpty()][String]$Name
	)
	
	$Chars=$Name.ToCharArray()
	$i=-1
	while ($true) {
		$i=$Name.IndexOfAny([IO.Path]::GetInvalidFileNameChars(),$i+1)
		if ($i -eq -1) {
			return $Chars -join ""
		}
		if ([int]$Chars[$i] -lt 32) {
			$Chars[$i]=[char]32 #replaced with spaces
			continue
		}
		$Chars[$i]=[char]([int]$Chars[$i]+0xfee0) #converts to full width chars
	}
}