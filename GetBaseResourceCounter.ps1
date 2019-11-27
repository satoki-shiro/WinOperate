Param ([int]$INTERVAL=5)

$HOMEDIR=(Split-Path $MyInvocation.MyCommand.Path -parent)

try
{
    $mResourceList = @()

    # Disk Resource Counter Set    
    #$mResourceList += "\FileSystem Disk Activity(_total)\FileSystem Bytes Written"
    #$mResourceList += "\FileSystem Disk Activity(_total)\FileSystem Bytes Read"
    #$mResourceList += "\LogicalDisk(_total)\Disk Write Bytes/sec"
    #$mResourceList += "\LogicalDisk(_total)\Disk Read Bytes/sec"
    #$mResourceList += "\LogicalDisk(_total)\Avg. Disk Write Queue Length"
    #$mResourceList += "\LogicalDisk(_total)\Avg. Disk Read Queue Length"
    #$mResourceList += "\LogicalDisk(_total)\% Idle Time"

    #$mResourceList += "\PhysicalDisk(_total)\Disk Write Bytes/sec"
    #$mResourceList += "\PhysicalDisk(_total)\Disk Read Bytes/sec"
    #$mResourceList += "\PhysicalDisk(_total)\Avg. Disk Write Queue Length"
    #$mResourceList += "\PhysicalDisk(_total)\Avg. Disk Read Queue Length"
    #$mResourceList += "\PhysicalDisk(_total)\% Idle Time"

    # Processor Resource Counter Set
    #$mResourceList += "\Processor(_total)\% Processor Time"
    #$mResourceList += "\Processor(_total)\% Interrupt Time"
    $mResourceList += "\Processor(_total)\% Idle Time"

    # Memory Resource Counter Set
    #$mResourceList += "\Memory\Available Bytes"
    #$mResourceList += "\Memory\Committed Bytes"
    #$mResourceList += "\Memory\Cache Faults/sec"
    #$mResourceList += "\Memory\Page Faults/sec"
    #$mResourceList += "\Memory\Pool Paged Bytes"
    #$mResourceList += "\Memory\Pool Nonpaged Bytes"
    $mResourceList += "\Memory\Cache Bytes"    

    #$mResourceList += "\Cache\Copy Read Hits %"
    #$mResourceList += "\Cache\Dirty Pages"
    #$mResourceList += "\Cache\Lazy Write Flushes/sec"

    # Network Resource Counter Set
    #$mResourceList += "\Per Processor Network Activity Cycles(_total)\Interrupt Cycles/sec"
    #$mResourceList += "\Per Processor Network Interface Card Activity(_total)\Sent Packets/sec"
    #$mResourceList += "\Per Processor Network Interface Card Activity(_total)\Received Packets/sec"
    #$mResourceList += "\Per Processor Network Interface Card Activity(_total)\Tcp Offload Send bytes/sec"
    #$mResourceList += "\Per Processor Network Interface Card Activity(_total)\Tcp Offload Receive bytes/sec"

    $mResourceList += "\Network Interface(intel*)\Packets Sent/sec"
    $mResourceList += "\Network Interface(intel*)\Packets Received/sec"
    $mResourceList += "\Network Interface(intel*)\Bytes Sent/sec"
    $mResourceList += "\Network Interface(intel*)\Bytes Received/sec"

    # Power Resource Counter
    $mResourceList += "\Power Meter(_total)\Power"   

    while($true)
    {
        $mCounter=Get-Counter -Counter $mResourceList            
        $mTimeStamp = ($mCounter.TimeStamp).ToString("yyyy-MM-dd HH:mm:ss")        
        $mResourceValue = ($mCounter.CounterSamples).CookedValue
        
        Write-Output "$($mTimeStamp)`t$($mResourceValue)"

        Sleep $INTERVAL
    }
}
catch
{
    
}
