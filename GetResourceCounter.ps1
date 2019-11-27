Param ([string] $RESOURCE="\PhysicalDisk(_Total)\% Disk Write Time", [int]$INTERVAL=5)

$HOMEDIR=(Split-Path $MyInvocation.MyCommand.Path -parent)

try
{
    while($true)
    {
        $mCounter=Get-Counter $RESOURCE
        $mTimeStamp = ($mCounter.TimeStamp).ToString("yyyy-MM-dd hh:mm:ss")       
        $mResourceValue = ($mCounter.CounterSamples).CookedValue
        
        Write-Output "$($mTimeStamp)`t$($mResourceValue)"

        Sleep $INTERVAL
    }
}
catch
{
    
}
