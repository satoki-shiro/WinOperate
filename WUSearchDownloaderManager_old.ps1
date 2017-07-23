####################################################
# FileName:       WUSearchDownloaderManager.ps1
# Authority:      Domain Administrator
# Operation Type: Normal
# Execution Type: Manual
# Purpose:        This script control task scheculers of all servers for downloading windows update patch. 
####################################################

Param ([string] $MODE)

# Load configuration file
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
[String]$confFile = Join-Path $HOMEDIR "ServerUpdateConf.xml"
[Xml]$confDoc = $null

try{
    [Xml]$confDoc = Get-Content -Path $confFile -ErrorAction Stop
}catch{
    Write-Output "ERROR: Cannot load configuration file!"
    Write-Output $Error[0]
    exit
}

[Xml.XmlElement]$conf = $confDoc.configuration

$serverSessionList = @()
$opeDir = $conf.init_info.ope_dir

$searchScript = $conf.init_info.search_script.InnerText
$searchTaskName =  $conf.init_info.search_script.taskname
$searchLogFile = "$($opeDir)\$($conf.init_info.search_script.logname)"

foreach($location in $conf.location_list.location)
{
    Write-Output "@$($location.name): Start search and download Windows update patches."
    foreach($server in $location.server_list.server)
    {
        # Get PSRemoting sessions
        $session = New-PSSession -ComputerName $server.ipv4Addr -Credential administrator

        # Make operation directory and Copy script from local server to remote ones.
        Invoke-Command -Session $session -ScriptBlock `
        { If(!(Test-Path $args[0])) { New-Item -ItemType Directory -Path $args[0] } } -ArgumentList $opeDir   
        
        Copy-Item -Path "$($HOMEDIR)\$($searchScript)" -Destination "$($opeDir)\" -ToSession $session

        $invokeScript = "$($opeDir)\$($searchScript)"        
        $updateType = $server.updateType

        Invoke-Command -Session $session -ScriptBlock `
        { schtasks /Create /tn "$($args[0])" /tr "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File`
        $($args[1]) -args $($args[2]) $($args[3])" /F /sc monthly /mo third /d thu /st 09:00:00 /ru system /rl highest } `
         -ArgumentList $searchTaskName,$invokeScript,$updateType,$searchLogFile

        Invoke-Command -Session $session -ScriptBlock `
        { schtasks /Run /tn "$($args[0])" } `
         -ArgumentList $searchTaskName

        # Get already installed hotfix patches and Write those to the log file.
        #$logFileDate = (Get-Date).ToString("yyyyMMdd")
        #$preInstalledLog = "$($opeDir)\$($logFileDate)_$($server.hostname)_preInstalled.log"
        
        #Invoke-Command -Session $session -ScriptBlock `
        #{ Get-WmiObject -Class "win32_quickfixengineering" | Select-Object -Property "HotfixID", `
        #    @{Name="InstalledOn"; Expression={([DateTime]($_.InstalledOn)).ToLocalTime()}},"Description" | `
        #    Export-Csv $args[0] -Encoding Default } -ArgumentList $preInstalledLog
        

        # Invoke search and download windows update patches.
        #$invokeScript = "$($opeDir)\$($searchScript)"
        #$workLog = $conf.init_info.work_log
        #$updateType = $server.updateType

        #TODO: Need to create schedule task
        #Invoke-Command -Session $session -ScriptBlock `
        #{ Start-Job -ScriptBlock { powershell.exe -File $args[0] -args $args[1],$args[2],$args[3] } } `
        #    -ArgumentList $invokeScript,$opeDir,$updateType,$workLog
        #
        #

        $serverSessionList += $session
    }
}


foreach($session in $serverSessionList)
{
    Remove-PSSession $session
}
