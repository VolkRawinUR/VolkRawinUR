$Username_Prefix = 'INF'
$Number_of_User = 20
$Start_Number_of_User = 1
$Number_of_Digit = 2
$RootPath='D:\'

For ($i = $Start_Number_of_User; $i -le $Number_of_User; $i++) {
	$Username=$Username_Prefix + "{0:d$Number_of_digit}" -f $i
	$FolderName=$Username
	$TargetPath=$RootPath + $FolderName
	If (!(Test-Path $TargetPath))
	{
		New-Item -Path $RootPath -Name $FolderName -ItemType "directory"
	}

	$ShareParameters = @{
		Name = $FolderName
		Path = $TargetPath
		FullAccess = $Username
	}
	New-SmbShare @ShareParameters
}