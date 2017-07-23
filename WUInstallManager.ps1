####################################################
# FileName:       WUInstallManager.ps1
# Authority:      Domain Administrator
# Operation Type: Normal
# Execution Type: Manual
# Purpose:        This script control task scheculers of all servers for installing windows update patch. 
####################################################

Param ([string] $MODE, [string]$EXCLUDELIST)

# Define Const values
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
$LOGSDIR = "$($HOMEDIR)\Logs"
If(!(Test-Path $LOGSDIR)) { New-Item -ItemType Directory -Path $LOGSDIR }
$STOP_MONITOR_FILE = "$($HOMEDIR)\STOP_MONITOR_WUINSTALL"

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
$mInstallScript = $mConf.init_info.install_script.InnerText
$mInstallTaskName =  $mConf.init_info.install_script.taskname
$mInstallLogFile = "$($mOpeDir)\$($mConf.init_info.install_script.logfile)"
$mInstallListFile = "$($mOpeDir)\$($mConf.init_info.install_script.listfile)"

$mCurDate = Get-Date -Format "yyyyMMdd"

Switch($MODE)
{
   "start"
   {
        foreach($location in $mConf.location_list.location)
        {
            Write-Output "@Target Location: $($location.name)"
            foreach($server in $location.server_list.server)
            {
                Write-Output "@@Target Server: $($server.hostname) - Start installing Windows update patches."

                # Get PSRemoting sessions
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser
                $targetListFile = "$($LOGSDIR)\$($mCurDate)_$($session.ComputerName)_$($mConf.init_info.search_script.listfile)"
                
                if((Get-ChildItem $targetListFile).Length -eq 0)
                { 
                    Write-Host "INFO: No install file."
                    continue; 
                }

                Copy-Item -Path "$($HOMEDIR)\$($mInstallScript)" -Destination "$($mOpeDir)\" -ToSession $session
                Copy-Item -Path "$($targetListFile)" -Destination "$($mInstallListFile)" -ToSession $session      

                $invokeScript = "$($mOpeDir)\$($mInstallScript)"
 
                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /Create /tn "$($args[0])" /tr "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File`
                $($args[1]) -args $($args[2]) $($args[3])" /F /sc monthly /mo third /d thu /st 09:00:00 /ru system /rl highest }`
                 -ArgumentList $mInstallTaskName,$invokeScript,$mInstallLogFile,$installListFile

                # Get already installed hotfix patches and Write those to the log file.
                $preInstalledLog = "$($LOGSDIR)\$($mCurDate)_$($session.ComputerName)_preInstalled.csv"
                Invoke-Command -Session $session -ScriptBlock `
                { Get-WmiObject -Class "win32_quickfixengineering" } | `
                Select-Object -Property "HotfixID", @{Name="InstalledOn"; Expression={([DateTime]($_.InstalledOn)).ToLocalTime()}},"Description" | `
                Export-Csv $preInstalledLog -Encoding Default

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /Run /tn "$($args[0])" }`
                 -ArgumentList $mInstallTaskName

                $mServerSessionList += $session
            }
        }
    } # End start

    "stop"
    {
        foreach($location in $mConf.location_list.location)
        {
            Write-Output "@Target Location: $($location.name)"
            foreach($server in $location.server_list.server)
            {
                Write-Output "@@Target Server: $($server.hostname) - Stop installing Windows update patches."
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /End /tn "$($args[0])" } `
                 -ArgumentList $mInstallTaskName

                Invoke-Command -Session $session -ScriptBlock `
                { schtasks /Change /Disable /tn "$($args[0])" } `
                 -ArgumentList $mInstallTaskName

                $mServerSessionList += $session
            }
        }
    }  # End stop

    "monitor"
    {
        $mTargetServerList = @()
        foreach($location in $mConf.location_list.location)
        {
            foreach($server in $location.server_list.server)
            {
                # Get PSRemoting sessions
                $session = New-PSSession -ComputerName $server.ipv4Addr -Credential $mRemoteUser
                $mServerSessionList += $session

                $installSize = Invoke-Command -Session $session { (Get-Content $args[0]).Length } -ArgumentList $mInstallListFile
                If($installSize -gt 0)
                {
                    $mTargetServerList += $session
                }
            }
        }
        
        $mCurDate = Get-Date -Format "yyyyMMdd"
        $mCompletedServer = @()

        while($true)
        {
            $resultArray = @()

            $resultArray += "HostName`tInstallStatus`tInstallFileNum`tMessage`tDiskSpace"
            foreach($session in $mTargetServerList)
            {
                $result = $null
                $result = Invoke-Command -Session $session -ScriptBlock `
                            { Get-Content $args[0] } -ArgumentList $mInstallLogFile

                # Checking whether installing is completed or not
                $matches = $null
                $matches = $result | Select-String -Pattern "End Install"
                $idx = [Array]::IndexOf($mCompletedServer,$session.ComputerName)
                If(($idx -eq -1) -and ($matches.Matches.Count -ge 1))
                {
                    $aftInstalledLog = "$($LOGSDIR)\$($mCurDate)_$($session.ComputerName)_aftInstalled.csv"
                    Invoke-Command -Session $session -ScriptBlock `
                    { Get-WmiObject -Class "win32_quickfixengineering" } | `
                    Select-Object -Property "HotfixID", @{Name="InstalledOn"; Expression={([DateTime]($_.InstalledOn)).ToLocalTime()}},"Description" | `
                    Export-Csv $aftInstalledLog -Encoding Default

                    $mCompletedServer += $session.ComputerName
                }

                $drive =  Invoke-Command -Session $session -ScriptBlock { Get-PSDrive C }
                $sumSize = [Math]::Round( (($($drive.used) + $($drive.free)) / (1024*1024*1024)) ,1)
                $freeSize = [Math]::Round( ($($drive.free)/(1024*1024*1024)) ,1)

                $resultArray += "$($result)`t$($freeSize)GB / $($sumSize)GB"

            }
            
            $resultLog = $resultArray -join("`r`n")
            Write-Host $resultLog
            
            If($mCompletedServer.Length -eq $mTargetServerList.Length)
            {
                Write-Host "INFO: Install complete!"
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
    } # End monitor
}

# Clear server remote sessions
foreach($session in $mServerSessionList)
{
    Remove-PSSession $session
}
