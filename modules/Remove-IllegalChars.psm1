function Remove-IllegalChars {
	<#
		.SYNOPSIS
			Replaces illegal characters in a file name.
		.DESCRIPTION
			ASCII control characters (0x00 to 0x1f) are simply removed from the name. Other
			illegal characters (e.g. '|' and '?') are replaced with their full-width counterparts.
			By default, spaces around these characters are also removed, use -KeepSpacesAroundChars if necessary.
		.EXAMPLE
			PS C:\> Remove-IllegalChars '"\/<>?*|:'
			＂＼／＜＞？＊｜：
			PS C:\> Remove-IllegalChars "Foo: Bar"
			Foo：Bar
			PS C:\> Remove-IllegalChars "Foo: Bar" -KeepSpacesAroundChars
			Foo： Bar
		.LINK
			https://docs.microsoft.com/en-us/dotnet/api/system.io.path.getinvalidfilenamechars?view=net-5.0
			https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file # todo: trailing dots
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline,Position=0)][AllowEmptyString()][String]$Name,
		[switch]$KeepSpacesAroundChars,
		[switch]$ConvertTrailingSpaces,
		[switch]$HasExtension, #keeps the extension from being truncated
		[ValidateRange("Positive")][int]$MaxLength=255 #extension is preserved (-HasExtension) even if MaxLength is smaller than the length of extension (plus the dot)
	)
	
	if (($Name -eq "") -or ($Name -eq $Null)) {
		return "null"
	}
	if ($HasExtension) {
		$BaseName=[IO.Path]::GetFileNameWithoutExtension($Name) #this breaks when name contains slashes todo: fix it
		$Name=$BaseName.Substring(0,[Math]::Max(0,$BaseName.Length-[Math]::Max(0,$Name.Length-$MaxLength)))+[IO.Path]::GetExtension($Name)
	} else {
		$Name=$Name.Substring(0,$(if($MaxLength -gt $Name.Length){$Name.Length}else{$MaxLength}))
	}
	$Chars=$Name.ToCharArray()
	$i=-1
	while (($i=$Name.IndexOfAny([IO.Path]::GetInvalidFileNameChars(),$i+1)) -gt 0) {
		if ([int]$Chars[$i] -lt 32) {
			$Chars[$i]=$null
			continue
		}
		$Chars[$i]=[char]([int]$Chars[$i]+0xfee0) #converts to full width chars
		if ($KeepSpacesAroundChars) {
			continue
		}
		if (($i -gt $Chars.GetLowerBound(0)) -and ([int]$Chars[$i-1] -eq 32)) {
			$Chars[$i-1]=$null
		}
		if (($i -lt $Chars.GetUpperBound(0)) -and ([int]$Chars[$i+1] -eq 32)) {
			$Chars[$i+1]=$null
		}
	}
	for ($i=-1;[int]$Chars[$i] -eq 32;--$i) {
		$Chars[$i]=$(if($ConvertTrailingSpaces){[char]0x3000}else{$null}) #this is inconsistent with how spaces are dealt with above, but I doubt anyone would want to use this feature
	}
	for ($i=0;[int]$Chars[$i-1] -eq 46;--$i) {}
	if ($i -eq 0) {
		return $Chars -join ""
	}
	if ((-$i % 3) -ne 0) {
		for (;$i -lt 0;++$i) {
			$Chars[$i]=[char]0xff0e #full width period
		}
		return $Chars -join ""
	}
	for ($Limit=$i+(-$i / 3);$i -lt $Limit;++$i) {
		$Chars[$i]=[char]8230 #'…'
	}
	for (;$i -lt 0;++$i) {
		$Chars[$i]=$null
	}
	return $Chars -join ""
}