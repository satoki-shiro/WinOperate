
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
$workLogFile = "$($opeDir)\$($conf.init_info.work_log)"

$installScript = $conf.init_info.install_script.InnerText
$installTaskName =  $conf.init_info.install_script.taskname

foreach($location in $conf.location_list.location)
{
    Write-Output "@$($location.name): Start search and download Windows update patches."
    foreach($server in $location.server_list.server)
    {
        # Get PSRemoting sessions
        $session = New-PSSession -ComputerName $server.ipv4Addr -Credential administrator
        Copy-Item -Path "$($HOMEDIR)\$($searchScript)" -Destination "$($opeDir)\" -ToSession $session


        $invokeScript = "$($opeDir)\$($installScript)"        
        $updateType = $server.updateType

        Invoke-Command -Session $session -ScriptBlock `
        { schtasks /Create /tn "$($args[0])" /tr "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File`
        $($args[1]) -args $($args[2]) $($args[3])" /F /sc monthly /mo third /d thu /st 09:00:00 /ru system /rl highest;`
          schtasks /Change /tn "$($args[0])" /Disable
         } -ArgumentList $installTaskName,$invokeScript,$updateType,$workLogFile

        ##################################
        # Preparation END
        ##################################

        # Get already installed hotfix patches and Write those to the log file.
        $logFileDate = (Get-Date).ToString("yyyyMMdd")
        $preInstalledLog = "$($opeDir)\$($logFileDate)_$($server.hostname)_preInstalled.log"

        Invoke-Command -Session $session -ScriptBlock `
        { schtasks /Change /tn "$($args[0])" /Enable; schtasks /Run /tn "$($args[0])";
        } -ArgumentList $searchTaskName

        $serverSessionList += $session
    }
}


foreach($session in $serverSessionList)
{
    Remove-PSSession $session
}
