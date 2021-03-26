function Join-CharsExclude {
	param (
		[Parameter(Mandatory,Position=0)][char[]]$CharArray,
		[Parameter(Position=1)][char]$Exclude=[char]0
	)
	
	$Sb=[System.Text.StringBuilder]::new()
	for ($i=$CharArray.GetLowerBound(0);$i -le $CharArray.GetUpperBound(0);++$i) {
		if ($CharArray[$i] -ne $Exclude) {
			[void]$Sb.Append($CharArray[$i])
		}
	}
	return $Sb.ToString()
}

function Remove-IllegalChars {
	<#
		.SYNOPSIS
			Removes illegal characters from a string.
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
			https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,ValueFromPipeline,Position=0)][AllowEmptyString()][String]$Name, #null is cast to string, [string]$null -eq ""
		[ValidateNotNullOrEmpty()][string]$NullOrEmptyPlaceholder="null",
		[switch]$KeepSpacesAroundChars,
		[switch]$ConvertTrailingSpaces,
		[switch]$HasExtension, #keeps the extension from being truncated
		[ValidateRange("Positive")][int]$MaxLength=255 #extension is preserved (-HasExtension) even if MaxLength is less than the length of extension (plus the dot)
	)
	
	if ($Name -eq "") {
		$Name=$NullOrEmptyPlaceholder
	}
	if ($HasExtension) {
		$BaseName=[IO.Path]::GetFileNameWithoutExtension($Name) #this breaks when name contains slashes todo: fix it
		$Name=$BaseName.Substring(0,[Math]::Max(0,$BaseName.Length-[Math]::Max(0,$Name.Length-$MaxLength)))+[IO.Path]::GetExtension($Name)
	} else {
		$Name=$Name.Substring(0,$(if($MaxLength -gt $Name.Length){$Name.Length}else{$MaxLength}))
	}
	$Chars=$Name.ToCharArray()
	$i=-1
	while (($i=$Name.IndexOfAny([IO.Path]::GetInvalidFileNameChars(),$i+1)) -gt -1) {
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
		$Chars[$i]=$(if($ConvertTrailingSpaces){[char]0x3000}else{$null}) #todo: fix inconsistency
	}
	for ($i=0;[int]$Chars[$i-1] -eq 46;--$i) {}
	if ($i -eq 0) {
		return Join-CharsExclude $Chars
	}
	if ((-$i % 3) -ne 0) {
		for (;$i -lt 0;++$i) {
			$Chars[$i]=[char]0xff0e #full width period
		}
		return Join-CharsExclude $Chars
	}
	for ($Limit=$i+(-$i / 3);$i -lt $Limit;++$i) {
		$Chars[$i]=[char]8230 #'…'
	}
	for (;$i -lt 0;++$i) {
		$Chars[$i]=$null
	}
	return Join-CharsExclude $Chars
}