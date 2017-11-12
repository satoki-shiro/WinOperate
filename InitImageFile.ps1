# Define Const values
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)

### STEP 1 START setting initial configuration ####
Write-Output "INFO: 初期設定を開始します　"

$mMountPath = "C:\"
$mLayoutFile = "$($HOMEDIR)\Layout.xml"
$mPackageFile = "$($HOMEDIR)\Windows10Base.ppkg"

# Import startmenu and taskbar layout
Import-StartLayout -LayoutPath $mLayoutFile -MountPath $mMountPath

# Uninstall unneeded packages
Install-ProvisioningPackage -PackagePath $mPackageFile

# Disable ipv6 interface and qos service for each network device
Disable-NetAdapterBinding -Name "*" -ComponentID ms_pacer
Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

Write-Output "INFO: 初期設定を完了しました。"
### STEP 1 END ###


