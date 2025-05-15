$DriveLetter="Y:"
$SharedPath="\\localhost\" + (whoami).Split('\')[1]

net use $driveLetter $sharedPath /persistent:yes
