########################################################
# FileName: GetBaseConfiguration.ps1
# Author: Shiro
# Update: Apr. 23, 2017
########################################################

Write-Output "@STEP 0 - Load configuration ..."
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
