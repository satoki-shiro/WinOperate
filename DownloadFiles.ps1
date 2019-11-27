
Start-BitsTransfer -DisplayName "MyBitsJob" -Source \\192.168.254.150\Temp\VirtualBox.exe -Destination C:\Temp -Asynchronous
$mBitsJob = Get-BitsTransfer | ?{$_.DisplayName -eq "MyBitsJob" }

$mTotalBytes=$mBitsJob.BytesTotal

While($mBitsJob.JobState -ne "Transferred")
{
    
    $mDownloadedPersent = [Math]::Round(((($mBitsJob.BytesTransferred)/$mTotalBytes)*100),1,[MidpointRounding]::AwayFromZero)
    Write-Progress -Activity "Downloaded File ..." -PercentComplete $mDownloadedPersent
}
Write-Host "$($mDownloadedPersent)%"
$mBitsJob | Complete-BitsTransfer