####################################################
# FileName:       ShutdownManager.ps1
# Authority:      Domain Administrator
# Operation Type: Critical
# Execution Type: Manual
# Purpose:        This script controls shutdown or reboot operation for servers. 
####################################################

Param ([string] $MODE, [string] $TYPE)

function CheckStartedPrimaryServer($HostName, $RemoteUser)
{
    $startStatus = "Running"
    
    $session = $null
    try
    {
        Test-WSMan $HostName -ErrorAction Stop | Out-Null

        $session = New-PSSession -ComputerName $HostName -Credential $RemoteUser

        $resultOfDiag = Invoke-Command -Session $session -ScriptBlock { dcdiag /test:Services }
        $matches = $null
        $matches = $resultOfDiag | Select-String -Pattern "失敗"
        If($matches.Matches.Count -gt 0)
        {
            Write-Host "WARN: AD Services are not started." 
            $false; return 
        }
        
        $statusDFS = Invoke-Command -Session $session -ScriptBlock { Get-Service DFS }
        If($statusDFS.Status -ne $startStatus)
        {
            Write-Host "WARN: DFS Service is not started." 
            $false; return 
        }
        
        $statusDNS = Invoke-Command -Session $session -ScriptBlock { Get-Service DNS }
        If($statusDNS.Status -ne $startStatus)
        {
            Write-Host "WARN: DNS Service is not started." 
            $false; return 
        }
                
    }
    catch
    {
        Write-Host "WARN: Remoting Service is not started."
        $false; return
    }
    finally
    {
        If($session -ne $null)
        {
            Remove-PSSession $session
        }
    }

    $true; return
}

# Define Const values
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
$LOGSDIR = "$($HOMEDIR)\Logs"
If(!(Test-Path $LOGSDIR)) { New-Item -ItemType Directory -Path $LOGSDIR }

# Load configuration file
[String]$CONFFILE = Join-Path $HOMEDIR "ServerShutdownConf.xml"
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
$mRemoteUser = $mConf.init_info.remote_user

$mCurDate = Get-Date -Format "yyyyMMdd"

Switch($MODE)
{
    "restart"
    {
        Switch($TYPE)
        {
           "primary"
           {
                foreach($location in $mConf.location_list.location)
                {
                    $locationPrimaryServer = $location.primary_server.ipv4Addr
                    $requiredRestart = $location.primary_server.requiredRestart

                    If($requiredRestart -eq "YES")
                    {
                        Write-Output "@Target Location: $($location.name) - Now Restart $($locationPrimaryServer)"            
            
                        Invoke-Command -ComputerName $locationPrimaryServer -Credential $mRemoteUser `
                         -ScriptBlock { shutdown /r /t 0 }
                    }
                }
 
            } # End primary

            "other"
            {
                $locationCount = $mConf.location_list.ChildNodes.Count
               
                $mCompletedLocation = @()

                while($true)
                {
                    foreach($location in $mConf.location_list.location)
                    {
                        $locationPrimaryServer = $location.primary_server.ipv4Addr
                        $isStarted = CheckStartedPrimaryServer $locationPrimaryServer $mRemoteUser

                        if($isStarted -eq $false)
                        {
                            Write-Output "@Target Location: $($location.name) - $($locationPrimaryServer) is not started"
                            continue
                        }

                        Write-Output "@Target Location: $($location.name) - $($locationPrimaryServer) is started"

                        $idx = [Array]::IndexOf($mCompletedLocation, $location.name)
                        If($idx -eq -1)
                        {
                            foreach($server in $location.server_list.server)
                            {
                                Write-Output "@@Target Server: $($server.hostname) - Now Restart"
                                Invoke-Command -ComputerName $($server.hostname) -Credential $mRemoteUser `
                                 -ScriptBlock { shutdown /r /t 0 }
                            }
                            $mCompletedLocation += $location.name
                        }
                    }

                    If($mCompletedLocation.Length -eq $locationCount)
                    {
                        Write-Host "INFO: All servers are restarted."
                        break
                    }

                    Sleep 5
                    cls
                }
            } # End other            
        } # End restart
    }

    "monitor"
    {
        foreach($location in $mConf.location_list.location)
        {
            $locationPrimaryServer = $location.primary_server.ipv4Addr

            try
            {
                Test-WSMan $locationPrimaryServer -ErrorAction Stop | Out-Null
                Write-Host "@Target Location: $($location.name) - $($locationPrimaryServer) is started"
            }
            catch
            {
                Write-Host "@Target Location: $($location.name) - $($locationPrimaryServer) is not started"
            }

            foreach($server in $location.server_list.server)
            {
                try
                {
                    Test-WSMan $server.ipv4Addr -ErrorAction Stop | Out-Null
                    Write-Host "@Target Location: $($location.name) - $($server.hostname) is started"
                }
                catch
                {
                    Write-Host "@Target Location: $($location.name) - $($server.hostname) is not started"
                }
            }
        }
    } # End monitor

}

# Clear server remote sessions
foreach($session in $mServerSessionList)
{
    Remove-PSSession $session
}
