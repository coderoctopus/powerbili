function New-UniqueEmptyDir {
	<#
		.SYNOPSIS
			Creates an empty directory. 
		.DESCRIPTION
			If the specified directory exists and is non-empty, a new directory (dir (2), dir (3), etc.)
			will be created.
		.RETURNS
			The absolute path to the directory.
		.PARAMETER Path
			Specifies the path to the directory. Accepts both absolute and relative paths.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory,Position=0)][String]$Path
	)
	
	$ProperPath=(New-Item -ItemType Directory -Force -Path $Path).FullName
	if ((Get-ChildItem $ProperPath -Force|Select-Object -First 1|Measure-Object).Count -eq 0) {
		return $ProperPath
	}
	New-UniqueEmptyDir $(if ($ProperPath -match " \(([0-9]+)\)$") {$ProperPath -replace $Matches[1],([int]$Matches[1]+1)} else {$ProperPath+" (2)"})
}