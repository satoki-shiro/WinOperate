
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

$searchScript = $conf.init_info.search_script.InnerText
$searchTaskName =  $conf.init_info.search_script.taskname

foreach($location in $conf.location_list.location)
{
    Write-Output "@$($location.name): Start monitoring status for Windows update."
    foreach($server in $location.server_list.server)
    {
        # Get PSRemoting sessions
        $session = New-PSSession -ComputerName $server.ipv4Addr -Credential administrator
        $serverSessionList += $session
    }
}

$mIsProgress = $true
$mCompleteCount = 0
$mResultLog = "$($HOMEDIR)\result.log"

while($mIsProgress)
{
    "HostName`tSearchFileNum`tSearchFileSize`tSearchStatus`tDownloadFileNum`tDownloadStatus`tDownloadMessage`tTaskStatus" > $mResultLog
    foreach($session in $serverSessionList)
    {
        $result = Invoke-Command -Session $session -ScriptBlock `
                    { Get-Content $args[0] } -ArgumentList $workLogFile
        $taskStatus = Invoke-Command -Session $session -ScriptBlock `
                    { schtasks /query /fo list /tn "$($args[0])" } -ArgumentList $searchTaskName | sls "状態"
        "$result`t$taskStatus" >> $mResultLog
    }
    Get-Content $mResultLog

    $mMatches = Select-String $mResultLog -Pattern "STATUS:END" -AllMatches
    If($mMatches.Matches.Count -eq $serverSessionList.Count)
    {
        $mIsProgress = $false
        Write-Host "INFO: Download complete!"
    }
    else
    {
        Clear-Content $mResultLog
    }
    Sleep 5
    cls
}

foreach($session in $serverSessionList)
{
    Remove-PSSession $session
}

exit
