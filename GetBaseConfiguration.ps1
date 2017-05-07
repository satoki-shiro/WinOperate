########################################################
# FileName: GetBaseConfiguration.ps1
# Author: Shiro
# Update: Apr. 23, 2017
########################################################

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
}

function ShowInstalledApplications(){
    $uninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 
    $localMachineReg=[microsoft.win32.registrykey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default)

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

    Get-NetFirewallRule | % {
        $firewallRuleAttr = @()
        $firewallRuleAttr += $_.DisplayName
        $firewallRuleAttr += $_.Profile
        $firewallRuleAttr += $_.Direction
        $firewallRuleAttr += $_.Action
        $firewallRuleAttr += $_.Enabled

        $firewallRule =  $firewallRuleAttr -join "`t"
        Write-Output $firewallRule
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

    Write-Output "インデックス`t名前`t詳細`tMACアドレス`t物理メディア種別`t状態`tIPv4アドレス`tIPv4ゲートウェイ`tDNSサーバ"

    Get-NetAdapter | % {
        $netAdapterAttr = @()
        $netAdapterAttr += $_.ifIndex
        $netAdapterAttr += $_.Name
        $netAdapterAttr += $_.InterfaceDescription
        $netAdapterAttr += $_.MacAddress
        $netAdapterAttr += $_.PhysicalMediaType
        $netAdapterAttr += $_.Status
                
        $_ | Get-NetIPConfiguration 2>$null | %{
            $netAdapterAttr += $_.IPv4Address.IPAddress
            $netAdapterAttr += $_.IPv4DefaultGateway.NextHop
            $dnsservers = $_.DNSServer | % { if($_.AddressFamily -eq 2){$_.ServerAddresses} }
            $netAdapterAttr += $dnsservers -join ","
        }

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
ShowBaseComputerInformation > "$($outFilePrefix)_01-BaseComputerInformation$($outFileSuffix)"
Write-Host "@STEP1: Done!"

Write-Host "@STEP2: Get installed application information ..."
ShowInstalledApplications > "$($outFilePrefix)_02-InstalledApplications$($outFileSuffix)"
Write-Host "@STEP2: Done!"

Write-Host "@STEP3: Get firewall information ..."
ShowFirewallRules > "$($outFilePrefix)_03-FirewallRules$($outFileSuffix)"
Write-Host "@STEP3: Done!"

Write-Host "@STEP4: Get service information ..."
ShowServiceList > "$($outFilePrefix)_04-ServiceList$($outFileSuffix)"
Write-Host "@STEP4: Done!"

Write-Host "@STEP5: Get network interface information ..."
ShowNetworkInterfaces > "$($outFilePrefix)_05-NetworkInterfaces$($outFileSuffix)"
Write-Host "@STEP5: Done!"

Write-Host "@STEP6: Get network routing information ..."
ShowNetworkRouting > "$($outFilePrefix)_06-NetworkRouting$($outFileSuffix)"
Write-Host "@STEP6: Done!"
