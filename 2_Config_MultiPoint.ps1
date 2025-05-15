### Configuration Area ###
$RDS_Available_Day=3650
$LogFileName="Log.txt"

$Username_Prefix = 'INF'
$Number_of_User = 20
$Number_of_Digit = 2
$Password = '1234'

$TimeZoneId = 'SE Asia Standard Time'   #Command list all available time zones - 'Get-TimeZone -ListAvailable'
### Configuration Area ###


## Function
function CreateLog{
    param(
        [String]$Message
        )
    $dt=get-date -format "dd-MM-yyyy HH:mm:ss"
    echo "$dt : $Message" > $LogFileName
    echo $Message
}

function WriteLog{
    param(
        [String]$Message
        )
    $dt=get-date -format "dd-MM-yyyy HH:mm:ss"
    echo "$dt : $Message" >> $LogFileName
    echo $Message
}

#Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -ErrorAction:SilentlyContinue
CreateLog -Message "Starting..."

## Set machine time zone to Bangkok (GMT+7)
Set-TimeZone -Id $TimeZoneId
WriteLog -Message "Set timezone to be $TimeZoneId."

## Setup MultiPoint server start to Console mode
Set-WmsSystem -BootToConsoleMode $True >$null
Set-WmsSystem -SuppressPrivacyNotification $True >$null
WriteLog -Message "Setup MultiPoint Server start to Console mode and disable 'Privacy Notification'."

## Delete GracePeriod registry key
if ((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" -ErrorAction:SilentlyContinue) -ne $null){
    .\SetACL.exe -on "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" -ot reg -actn setowner -ownr "n:Administrators" >$null
    .\SetACL.exe -on "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" -ot reg -actn ace -ace "n:Administrators;p:full" >$null
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod" /f >$null
    WriteLog -Message "GracePeriod registry deleted."
}else{
    WriteLog -Message "GracePeriod registry does not exist."
}

### Set machine time to Future
net stop w32time >$null
$FutureDateTime=Set-Date -Date (Get-Date).AddDays($RDS_Available_Day)
WriteLog -Message "Change date to be $FutureDateTime."

## Re-create GracePeriod registry key with Future time
tlsbln >$null
WriteLog -Message "Re-create GracePeriod registry key by 'tlsbln' command."

## Set machine time to Current
net start w32time >$null
WriteLog -Message "Change date to be present day."

## Call license time period before expire
tlsbln >$null
WriteLog -Message "Run 'tlsbln' command for check remaining days of RDP license."

## Hide notifications about RD Licensing
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableTerminalServerTooltip /t REG_DWORD /d 1 /f >$null
WriteLog -Message "Create 'fDisableTerminalServerTooltip'=1 registry for hide notifications about RD Licensing."

## Hide Windows watermark
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\svsvc" /v Start /f >$null
reg add "HKLM\SYSTEM\CurrentControlSet\Services\svsvc" /v Start /t REG_DWORD /d 4 /f >$null
WriteLog -Message "Change 'Start'=4 registry for hide Windows watermark."

## Change password complexity policy
WriteLog -Message "Disable 'Password complexity' policy..."
secedit /export /cfg secpol.cfg >$null
(Get-Content secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg secpol.cfg /areas SECURITYPOLICY >$null
rm -force secpol.cfg -confirm:$false
WriteLog -Message "'Password complexity' policy disabled."

## Create standard user
WriteLog -Message "Create user..."
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force

FOR ($i=1;$i -le $Number_of_User;$i++){
    $username=$Username_Prefix + "{0:d$Number_of_digit}" -f $i
    $credential = New-Object System.Management.Automation.PSCredential $username, $securePassword

    if ((Get-WmsUser -Name $username) -ne $null){
        Set-WmsUser -Credential $credential
        WriteLog -Message "'$username' already exist, just set password."
    }else{
        New-WmsUser -Description $username -FullName $username -Credential $credential -UserType Standard
        WriteLog -Message "'$username' created."
    }
}

## Add Thai Keyboard
$LangList = Get-WinUserLanguageList
$LangList.Add("th-TH")
Set-WinUserLanguageList -LanguageList $LangList -Force
WriteLog -Message "Add Thai Keyboard."


## To Request Admin set Grave Accent(`) to be hot key for change keyboard language
echo "***************************************************************************************"
echo "***************************************************************************************"
echo "      Please!!!, set Grave Accent(`) to be hot key for change keyboard language.       "
echo "***************************************************************************************"
echo "***************************************************************************************"
pause
echo ""
echo ""
WriteLog -Message "Set Grave Accent(`) to be hot key for change keyboard language have done."
echo ""
echo ""

## To Request Admin copy current settings of 'Welcome screen and langauge' to new user accounts
echo "***************************************************************************************"
echo "***************************************************************************************"
echo "Please!!!, Copy current settings of 'Welcome screen and langauge' to new user accounts."
echo "***************************************************************************************"
echo "***************************************************************************************"
pause
echo ""
echo ""
WriteLog -Message "Copy current settings of 'Welcome screen and langauge' to new user accounts have done."

WriteLog -Message "Finished..."
pause