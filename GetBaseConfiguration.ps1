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

    $computerName = '"ホスト名","' +  $win32Computer.Name + '"'
    Write-Output $computerName

    $computerDomain = '"ドメイン","' +  $win32Computer.Domain + '"'
    Write-Output $computerDomain

    $os = '"OS 名","' +  $win32OS.caption + '"'
    Write-Output $os

    $osBuild = '"OS バージョン","' +  $win32OS.Version + '"'
    Write-Output $osBuild

    $osArch = '"OS アーキテクチャ","' +  $win32OS.OSArchitecture + '"'
    Write-Output $osArch

    $osType = '"OS 構成","' +  $win32OS.ProductType + '"'
    Write-Output $osType

    $computerManufacturer = '"製造元","' +  $win32Computer.Manufacturer + '"'
    Write-Output $computerManufacturer

    $computerFamily = '"システム ファミリー","' +  $win32Computer.SystemFamily + '"'
    Write-Output $computerFamily

    $computerModel = '"システム モデル","' +  $win32Computer.Model + '"'
    Write-Output $computerModel

    $biosSerial = '"シリアル番号","' +  $win32BIOS.SerialNumber + '"'
    Write-Output $biosSerial

    $computerType = '"システムの種類","' +  $win32Computer.SystemType + '"'
    Write-Output $computerType

    $biosInfo = '"BIOS バージョン","' + $win32BIOS.SMBIOSBIOSVersion + '"'
    Write-Output $biosInfo

    $processorInfo = '"プロセッサ","' + $win32Processor.Name + '"'
    Write-Output $processorInfo

    $memoryInfo = '"物理メモリサイズ","' + ($win32OS.TotalVisibleMemorySize/1024).ToString("#,0") + ' MB"'
    Write-Output $memoryInfo

    $culture = Get-Culture
    $osLanguage = '"使用言語","' + $culture.Name + " " + $culture.DisplayName + '"'
    Write-Output $osLanguage

    $currentTime = Get-Date
    $utcOffset = [System.Timezone]::CurrentTimeZone.GetUtcOffset($currentTime)
    $offsetTime = $utcOffset.Hours.ToString("00") + ":" + $utcOffset.Minutes.ToString("00")
    if($utcOffset.Hours -gt 0){
        $offsetTime = "+" + $offsetTime
    }

    $timeZone = '"タイム ゾーン","(UTC'+  $offsetTime + ') ' + [System.Timezone]::CurrentTimeZone.StandardName + '"'
    Write-Output $timeZone
}

function ShowInstalledApplications(){
    $uninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 
    $localMachineReg=[microsoft.win32.registrykey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Default)

    $localMachineRegKey=$localMachineReg.OpenSubKey($uninstallKey) 
    $subKeys=$localMachineRegKey.GetSubKeyNames() 

    foreach($key in $subKeys){

        $thisKey=$uninstallKey+”\\”+$key 
        $thisSubKey=$reg.OpenSubKey($thisKey) 

        $applicationAttr = @()
        $applicationAttr += $thisSubKey.GetValue("DisplayName")
        $applicationAttr += $thisSubKey.GetValue("DisplayVersion")
        $applicationAttr += $thisSubKey.GetValue("Publisher")

        $application =  '"' + ($applicationAttr -join '","') + '"'
        Write-Output $application

    }
}

function ShowFirewallRules(){
    Get-NetFirewallRule | % {
        $firewallRuleAttr = @()
        $firewallRuleAttr += $_.DisplayName
        $firewallRuleAttr += $_.Profile
        $firewallRuleAttr += $_.Direction
        $firewallRuleAttr += $_.Action
        $firewallRuleAttr += $_.Enabled

        $firewallRule =  '"' + ($firewallRuleAttr -join '","') + '"'
        Write-Output $firewallRule
    }
}

function ShowServiceList(){
        
    Get-Service | %{
        $serviceAttr = @()
        $serviceAttr += $_.DisplayName
        $serviceAttr += $_.Status
        $serviceAttr += $_.StartType
        
        $filter = 'Name=' + '"' + $_.Name + '"'
        $startName = (Get-WmiObject Win32_Service -Filter $filter).StartName
        $serviceAttr += $startName

        $services =  '"' + ($serviceAttr -join '","') + '"'
        Write-Output $services
    }
}

function ShowNetworkInterfaces(){
    Get-NetAdapter | % {
        $netAdapterAttr = @()
        $netAdapterAttr += $_.Name
        $netAdapterAttr += $_.InterfaceDescription
        $netAdapterAttr += $_.MacAddress
        $netAdapterAttr += $_.PhysicalMediaType
        $netAdapterAttr += $_.Status

        $netAdapters =  '"' + ($netAdapterAttr -join '","') + '"'
        Write-Output $netAdapters

        $_ | Get-NetIPConfiguration 2>$null | %{
            $_.IPv4Address.IPAddress
            $_.IPv4DefaultGateway.NextHop
            $_.DNSServer | % { if($_.AddressFamily -eq 2){$_.ServerAddresses} }
        }
        
    }
}

########################################################
# Entry Point
########################################################

#ShowBaseComputerInformation
#ShowInstalledApplications
#ShowFirewallRules
#ShowServiceList
ShowNetworkInterfaces
