########################################################
# FileName: GetBaseConfiguration.ps1
# Author: Shiro
# Update: Apr. 23, 2017
########################################################


$FWprofileTypes= @{2147483647=”All”;1=”Domain”; 2=”Private”; 3=”Domain,Private”; 4=”Public”; 6=”Private,Public”}
$FwAction      =@{1=”Allow”; 0=”Block”}
$FwProtocols   =@{1=”ICMPv4”;2=”IGMP”;6=”TCP”;17=”UDP”;41=”IPv6”;43=”IPv6Route”; 44=”IPv6Frag”;
                  47=”GRE”; 58=”ICMPv6”;59=”IPv6NoNxt”;60=”IPv6Opts”;112=”VRRP”; 113=”PGM”;115=”L2TP”;
                  ”ICMPv4”=1;”IGMP”=2;”TCP”=6;”UDP”=17;”IPv6”=41;”IPv6Route”=43;”IPv6Frag”=44;”GRE”=47;
                  ”ICMPv6”=48;”IPv6NoNxt”=59;”IPv6Opts”=60;”VRRP”=112; ”PGM”=113;”L2TP”=115}
$FWDirection   =@{1=”Inbound”; 2=”outbound”; ”Inbound”=1;”outbound”=2} 
 

Function Convert-FWProfileType
    {Param ($ProfileCode)
    $FWprofileTypes.keys | foreach –begin {[String[]]$descriptions= @()} `
                                    -process {if ($profileCode -bAND $_) {$descriptions += $FWProfileTypes[$_]} } `
                                    –end {$descriptions}
}

Function Get-FirewallConfig {
    $fw=New-object –comObject HNetCfg.FwPolicy2
    "Active Profiles(s) :" + (Convert-fwprofileType $fw.CurrentProfileTypes)
    @(1,2,4) | select @{Name=“Network Type”     ;expression={$FwProfileTypes[$_]}},
                       @{Name=“Firewall Enabled” ;expression={$fw.FireWallEnabled($_)}},
                       @{Name=“Block All Inbound”;expression={$fw.BlockAllInboundTraffic($_)}},
                       @{name=“Default In”       ;expression={$FwAction[$fw.DefaultInboundAction($_)]}},
                       @{Name=“Default Out”      ;expression={$FwAction[$fw.DefaultOutboundAction($_)]}}|
                Format-Table -auto
}

function ShowBaseComputerInformation(){
    $win32Computer =  Get-WmiObject -Class Win32_ComputerSystem
    $win32OS = Get-WmiObject Win32_OperatingSystem
    $win32BIOS = Get-WmiObject -Class Win32_BIOS
    $win32Processor = Get-WmiObject Win32_Processor 

    Write-Output "ホスト名`t$($win32Computer.Name)"
    Write-Output "ドメイン`t$($win32Computer.Domain)"
    Write-Output "OS 名`t$($win32OS.caption)"
    Write-Output "OS バージョン`t$($win32OS.Version)"
    Write-Output "OS アーキテクチャ`t$($win32OS.OSArchitecture)"
    
    $productType = $win32OS.ProductType
    Write-Output "OS 構成`t$($win32OS.ProductType)"

    Write-Output "製造元`t$($win32Computer.Manufacturer)"
    Write-Output "システム ファミリー`t$($win32Computer.SystemFamily)"
    Write-Output "システム モデル`t$($win32Computer.Model)"
    Write-Output "シリアル番号`t$($win32BIOS.SerialNumber)"
    Write-Output "システムの種類`t$($win32Computer.SystemType)"
    Write-Output "BIOS バージョン`t$($win32BIOS.SMBIOSBIOSVersion)"
    Write-Output "プロセッサ`t$($win32Processor.Name)"

    $memorySize = (($win32OS.TotalVisibleMemorySize)/1024).ToString('#,0')
    Write-Output "物理メモリサイズ`t$($memorySize) MB"

    $culture = Get-Culture
    Write-Output "使用言語`t$($culture.Name)  $($culture.DisplayName)"

    $currentTime = Get-Date
    $utcOffset = [System.Timezone]::CurrentTimeZone.GetUtcOffset($currentTime)
    $offsetTime = $utcOffset.Hours.ToString("00") + ":" + $utcOffset.Minutes.ToString("00")
    if($utcOffset.Hours -gt 0){
        $offsetTime = "+" + $offsetTime
    }

    $timeZone = "タイム ゾーン`t(UTC $($offsetTime)) $([System.Timezone]::CurrentTimeZone.StandardName)"
    Write-Output $timeZone
    
    
    
    #Check Administrator Users
    $Computer = $env:COMPUTERNAME
    $ADSIComputer = [ADSI]("WinNT://$Computer,computer") 
    $group = $ADSIComputer.psbase.children.find('Administrators',  'Group') 
    $group.psbase.invoke("members")  | ForEach{
        $localAdminUser = $_.GetType().InvokeMember("Name",  'GetProperty',  $null,  $_, $null)
        $trgUser =  Get-WMIObject Win32_UserAccount -Filter "LocalAccount=True and Name='$($localAdminUser)'"
        Write-Output "$($trgUser.Name)`t$($trgUser.Status)`t$($trgUser.PasswordExpires)"  
    }
    #Check Remote Desktop Users
    $group = $ADSIComputer.psbase.children.find('Remote Desktop Users',  'Group') 
    $group.psbase.invoke("members")  | ForEach{
        $remoteUser = $_.GetType().InvokeMember("Name",  'GetProperty',  $null,  $_, $null)
        $trgUser =  Get-WMIObject Win32_UserAccount -Filter "LocalAccount=False and Name='$($remoteUser)'"
        Write-Output "$($trgUser.Name)`t$($trgUser.Status)`t$($trgUser.PasswordExpires)"  
    } 
    
}

function ShowInstalledApplications(){
    $computerName=$env:computername
    $uninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 
    $localMachineReg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computerName)

    $localMachineRegKey=$localMachineReg.OpenSubKey($uninstallKey) 
    $subKeys=$localMachineRegKey.GetSubKeyNames() 

    Write-Output "アプリケーション名`tバージョン`t発行元`tインストール日"

    foreach($key in $subKeys){
        $thisKey=$uninstallKey+”\\”+$key
        $thisSubKey=$localMachineReg.OpenSubKey($thisKey) 
  
        $applicationAttr = @()
        if($thisSubKey.GetValue("DisplayName").length -gt 0){
            $applicationAttr += $thisSubKey.GetValue("DisplayName")
        }
        if($thisSubKey.GetValue("DisplayVersion").length -gt 0){
            $applicationAttr += $thisSubKey.GetValue("DisplayVersion")
        }
        if($thisSubKey.GetValue("Publisher").length -gt 0){
            $applicationAttr += $thisSubKey.GetValue("Publisher")
        }
        if($thisSubKey.GetValue("InstallDate").length -gt 0){
            $installDate = $thisSubKey.GetValue("InstallDate")
            $applicationAttr += "$($installDate.Substring(0,4))-$($installDate.Substring(4,2))-$($installDate.Substring(6,2))" 
        }        
        
        if($applicationAttr.length -gt 0){
            $application =  $applicationAttr -join "`t"
            Write-Output $application
        }

    }
}

function ShowFirewallRules(){
    Write-Output "名前`tプロファイル`t方向`t操作`t有効"
    
    $rules=(New-object –comObject HNetCfg.FwPolicy2).rules
    $rules | sort direction,name | %{
        Write-Output "$($_.Name)`t$($FWprofileTypes[$_.profiles])`t$($FWDirection[$_.direction])`t$($FWAction[$_.action])`t$($_.Enabled)"
    }
}

function ShowServiceList(){

    Write-Output "名前`t状態`tスタートアップの種類`tログオン"
        
    Get-Service | %{
        $serviceAttr = @()
        $serviceAttr += $_.DisplayName
        $serviceAttr += $_.Status
        
        $filter = 'Name=' + '"' + $_.Name + '"'
        $startType = (Get-WmiObject Win32_Service -Filter $filter).StartMode
        $serviceAttr += $startType
        $startName = (Get-WmiObject Win32_Service -Filter $filter).StartName
        $serviceAttr += $startName

        $services =  $serviceAttr -join "`t"
        Write-Output $services
    }
}

function ShowNetworkInterfaces(){

    Write-Output "インデックス`t名前`t詳細`tMACアドレス`t物理メディア種別`t状態`tIPアドレス"
    $interfaceConf = Get-WMIObject -class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
    $interfaceConf | % {
        $netAdapterAttr = @()
        $interfaceIndex = $_.InterfaceIndex
               
        $netAdapterAttr += $interfaceIndex
        $netAdapterAttr += $_.Name
        $netAdapterAttr += $_.Description
        $netAdapterAttr += $_.MACAddress
        
        $interface = Get-WMIObject -Class Win32_NetworkAdapter -Filter "InterfaceIndex=$($interfaceIndex)"
        $netAdapterAttr += $interface.AdapterType
        $netAdapterAttr += $interface.NetEnabled
        $netAdapterAttr += $_.IPAddress

        $netAdapters =  $netAdapterAttr -join "`t"
        Write-Output $netAdapters
    }
}

function ShowNetworkRouting(){

    Write-Output "インデックス`tプレフィックス`tネクストホップ`tメトリックス"

    $netRouteAttr = @()
    Get-NetRoute | % {
        $netRouteAttr += $_.ifIndex
        $netRouteAttr += $_.DestinationPrefix
        $netRouteAttr += $_.NextHop
        $netRouteAttr += $_.RouteMetric

        $netRoute =  $netRouteAttr -join "`t"
        Write-Output $netRoute
    }

}

########################################################
# Entry Point
########################################################
$HOMEDIR = ""

$outFilePrefix = (hostname) + "_" + (Get-Date -Format "yyyyMMdd")
$outFileSuffix = ".tsv"

Write-Host "@STEP1: Get basic computer information ..."
ShowBaseComputerInformation
#ShowBaseComputerInformation > "$($outFilePrefix)_01-BaseComputerInformation$($outFileSuffix)"
Write-Host "@STEP1: Done!"


Write-Host "@STEP2: Get installed application information ..."
ShowInstalledApplications
#ShowInstalledApplications > "$($outFilePrefix)_02-InstalledApplications$($outFileSuffix)"
Write-Host "@STEP2: Done!"

#Write-Host "@STEP3: Get firewall information ..."
#ShowFirewallRules 
#ShowFirewallRules > "$($outFilePrefix)_03-FirewallRules$($outFileSuffix)"
#Write-Host "@STEP3: Done!"

#Write-Host "@STEP4: Get service information ..."
#ShowServiceList
#ShowServiceList > "$($outFilePrefix)_04-ServiceList$($outFileSuffix)"
#Write-Host "@STEP4: Done!"

Write-Host "@STEP5: Get network interface information ..."
ShowNetworkInterfaces
#ShowNetworkInterfaces > "$($outFilePrefix)_05-NetworkInterfaces$($outFileSuffix)"
Write-Host "@STEP5: Done!"

exit

Write-Host "@STEP6: Get network routing information ..."
ShowNetworkRouting > "$($outFilePrefix)_06-NetworkRouting$($outFileSuffix)"
Write-Host "@STEP6: Done!"
