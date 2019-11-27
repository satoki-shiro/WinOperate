Param ([int]$INTERVAL=5)

$HOMEDIR=(Split-Path $MyInvocation.MyCommand.Path -parent)

$PROCESSLIST = Get-Process | Select Name 

try
{
    $mResourceList = @()

    # Disk Resource Counter Set    
    #$mResourceList += "\Process(*)\% User Time"
    #$mResourceList += "\Process(*)\% Privileged Time"
    #$mResourceList += "\Process(*)\Page Faults/sec"
    #$mResourceList += "\Process(*)\Working Set"
    #$mResourceList += "\Process(*)\Pool Paged Bytes"
    #$mResourceList += "\Process(*)\Pool Nonpaged Bytes"
    #$mResourceList += "\Process(*)\IO Read Bytes/sec"
    #$mResourceList += "\Process(*)\IO Write Bytes/sec"
    
    while($true)
    {
        $mCounter=Get-Counter -Counter $mResourceList          
        $mTimeStamp = ($mCounter.TimeStamp).ToString("yyyy-MM-dd HH:mm:ss")        
        
#$mCounter.CounterSamples | Get-Member
        #$mCounter.CounterSamples | Select InstanceName, CookedValue
        $mCounter.CounterSamples.Length
        exit
        Sleep $INTERVAL
    }
}
catch
{
    
}
