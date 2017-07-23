####################################################
# FileName:       WUSearchDownloaderManager.ps1
# Authority:      Domain Administrator
# Operation Type: Normal
# Execution Type: Manual
# Purpose:        This script control task scheculers of all servers for downloading windows update patch. 
####################################################

Param ([string] $MODE)

# Define Const values
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
$LOGSDIR = "$($HOMEDIR)\Logs"
If(!(Test-Path $LOGSDIR)) { New-Item -ItemType Directory -Path $LOGSDIR }
$STOP_MONITOR_FILE = "$($HOMEDIR)\STOP_MONITOR_WUSEARCHDOWNLOAD"

# Load configuration file
[String]$CONFFILE = Join-Path $HOMEDIR "ServerUpdateConf.xml"
[Xml]$mConfDoc = $null

try{
    [Xml]$mConfDoc = Get-Content -Path $CONFFILE -ErrorAction Stop
}catch{
    Write-Output "ERROR: Cannot load configuration file!"
    Write-Output $Error[0]
    exit
}

[Xml.XmlElement]$mConf = $mConfDoc.configuration

$mServerSessionList = @()
$mOpeDir = $mConf.init_info.ope_dir

$mRemoteUser = $mConf.init_info.remote_user
$mSearchScript = $mConf.init_info.search_script.InnerText
$mSearchTaskName =  $mConf.init_info.search_script.taskname
$mSearchLogFile = "$($mOpeDir)\$($mConf.init_info.search_script.logfile)"
$mDownLoadListFile = "$($mOpeDir)\$($mConf.init_info.search_script.listfile)"

Switch($MODE)
{
   "start"
    {
        foreach($location in $mConf.location_list.location)
        {
            Write-Output "@Target Location: $($location.name)"
            foreach($server in $location.server_list.server)
            {
                Write-Output "@@Target Server: $($server.hostname) - Start searching and downloading Windows update patches."

                # Get PSRemoting sessions
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser

                # Make operation directory and Copy script from local server to remote ones.
                Invoke-Command -Session $session -ScriptBlock `
                { If(!(Test-Path $args[0])) { New-Item -ItemType Directory -Path $args[0] } } -ArgumentList $mOpeDir   
        
                Copy-Item -Path "$($HOMEDIR)\$($mSearchScript)" -Destination "$($mOpeDir)\" -ToSession $session

                $invokeScript = "$($mOpeDir)\$($mSearchScript)"        
                $updateType = $server.updateType         

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /Create /tn "$($args[0])" /tr "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File`
                $($args[1]) -args $($args[2]) $($args[3]) $($args[4])" /F /sc monthly /mo third /d thu /st 09:00:00 /ru system /rl highest } `
                 -ArgumentList $mSearchTaskName,$invokeScript,$updateType,$mSearchLogFile,$mDownLoadListFile

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /Run /tn "$($args[0])" } `
                 -ArgumentList $mSearchTaskName

                $mServerSessionList += $session
            }
        }

    } # END start
 
    "stop"
    {
        foreach($location in $mConf.location_list.location)
        {
            Write-Output "@Target Location: $($location.name)"
            foreach($server in $location.server_list.server)
            {
                Write-Output "@@Target Server: $($server.hostname) - Stop searching and downloading Windows update patches."
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /End /tn "$($args[0])" } `
                 -ArgumentList $mSearchTaskName

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /Change /Disable /tn "$($args[0])" } `
                 -ArgumentList $mSearchTaskName

                $mServerSessionList += $session
            }
        }
    } # END stop
    
    "clear"
    {
        $contentLocation = $mConf.init_info.content_location
        If($contentLocation.length -eq 0)
        {
            Write-Host "ERROR: Cannot clear selected path. Please check content location path in the configuraiton file."
        }

        foreach($location in $mConf.location_list.location)
        {
            Write-Output "@Target Location: $($location.name)"
            foreach($server in $location.server_list.server)
            {
                Write-Output "@@Target Server: $($server.hostname) - Clear downloaded windows update patches."

                # Get PSRemoting sessions
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser
                Invoke-Command -Session $session -ScriptBlock { Stop-Service wuauserv }
                Invoke-Command -Session $session -ScriptBlock { Remove-Item -Path "$($args[0])\*" -Force -Recurse } -ArgumentList $contentLocation
                Invoke-Command -Session $session -ScriptBlock { Start-Service wuauserv }

                $mServerSessionList += $session
            }
        }
    } # END clear

    "monitor"
    {
        foreach($location in $mConf.location_list.location)
        {
            foreach($server in $location.server_list.server)
            {
                # Get PSRemoting sessions
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser
                $mServerSessionList += $session
            }
        }
        
        $mCurDate = Get-Date -Format "yyyyMMdd"
        $mCompletedServer = @()

        while($true)
        {
            $resultArray = @()
            $matches = $null

            $resultArray += "HostName`tSearchStatus`tSearchFileNum`tSearchFileSize`tDownloadStatus`tDownloadFileNum`tMessage"
            foreach($session in $mServerSessionList)
            {
                $result = Invoke-Command -Session $session -ScriptBlock `
                            { Get-Content $args[0] } -ArgumentList $mSearchLogFile
                $resultArray += "$($result)"

                $matches = $null
                $matches = $result | Select-String -Pattern "End Download"
                $idx = [Array]::IndexOf($mCompletedServer,$session.ComputerName)
                If(($idx -eq -1) -and ($matches.Matches.Count -ge 1))
                {
                    $mTrgDownLoadListFile = "$($LOGSDIR)\$($mCurDate)_$($session.ComputerName)_$($mConf.init_info.search_script.listfile)"

                    Copy-Item -Path $mDownLoadListFile -Destination $mTrgDownLoadListFile -FromSession $session
                    
                    $mCompletedServer += $session.ComputerName
                }
            }

            $resultLog = $resultArray -join("`r`n")
            Write-Host $resultLog
            
            If($mCompletedServer.Length -eq $mServerSessionList.Count)
            {
                Write-Host "INFO: Download complete!"
                break
            }

            if(Test-Path $STOP_MONITOR_FILE)
            {
                Write-Host "INFO: Stop monitoring install. If you continue to monitor, delete $($STOP_MONITOR_FILE) file."
                break
            }
            Sleep 5
            cls
        }
    } # END Monitor
}

# Clear server remote sessions
foreach($session in $mServerSessionList)
{
    Remove-PSSession $session
}
