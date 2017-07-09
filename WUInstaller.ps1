function SearchWindowsUpdate([__ComObject]$UpdateSearcher, [__ComObject]$UpdateCollection)
{
    $mHostName = $env:COMPUTERNAME
    $mResultOfSearch = $UpdateSearcher.Search("IsInstalled = 0 and IsHidden = 0")

    $mResultDescription = $RESULT_DESCRIPTION[$mResultOfSearch.ResultCode]
    
    $mUpdateItemCount = $mResultOfSearch.updates.count
    If($mUpdateItemCount -eq 0)
    {
       "$($mHostName)`t0`t0`t$($mResultDescription)"
        Return
    }

    $mUpdateItemSize = 0
    ForEach($updateItem in $mResultOfSearch.updates)
    {
        $mUpdateItemSize += $updateItem.MaxDownloadSize
        $UpdateCollection.Add($updateItem) | Out-Null
    }
    "$($mHostName)`t$($mUpdateItemCount)`t$([Math]::Round($mUpdateItemSize/(1024*1024),1))MB`t$($mResultDescription)"
    
 }

function DownloadWindowsUpdate([__ComObject]$UpdateSearcher, [__ComObject]$UpdateCollection, [__ComObject]$UpdateSession, $PreLogMessage, $LogFile)
{
    $mDownloadCount = 0

    ForEach($downloadItem in $UpdateCollection)
    {
        $mDownloadResult = 0

        $oTempColl = New-Object -ComObject "Microsoft.Update.UpdateColl"
		$oTempColl.Add($downloadItem) | Out-Null
        $oDownloader = $UpdateSession.CreateUpdateDownloader()
        $oDownloader.Updates = $oTempColl
        Try
        {
            $mDownloadResult = $oDownloader.Download()
        }
        Catch
        {
            If($_ -match "HRESULT: 0x80240044")
			{
				Write-Output "$($PreLogMessage)`t0`tSTATUS:END`tERROR:You cannot perform this task due to your privilege." > $LogFile
			} 
            Return
        }

        If($mDownloadResult.ResultCode -eq 2){
            $mDownloadCount++
        }

        Write-Output "$($PreLogMessage)`t$($mDownloadCount) / $($UpdateCollection.count)`tSTATUS:PROGRESS`tINFO:Now Downloading ..." > $LogFile
        #Write-Progress -Activity "Download files..." -PercentComplete $mDownloadCount `
        #    -CurrentOperation "$($mDownloadCount) / $($UpdateCollection.count)"
    }

   
    $mRequiredReboot = "NO"
    $mResultOfSearch = $UpdateSearcher.Search("IsInstalled = 0 and IsHidden = 0")

    ForEach($updateItem in $mResultOfSearch.updates)
    {
        If($updateItem.InstallationBehavior.RebootBehavior -gt 0)
        {
            $mRequiredReboot = "YES"
        }
    }

    If($UpdateCollection.count -gt $mDownloadCount)
    {
        Write-Output "$($PreLogMessage)`t$($mDownloadCount)`tSTATUS:END`tWARN:Failed to download some files. Reboot is $($mRequiredReboot)" > $LogFile
    }
    else
    {
        Write-Output "$($PreLogMessage)`t$($mDownloadCount)`tSTATUS:END`tINFO:Download completed. Reboot is $($mRequiredReboot)" > $LogFile
    }
}

##########################################
# 
#  ENTRY POINT
#
##########################################

$pUpdateType = $Args[1]
$pLogFile = $Args[2]

If($pUpdateType -eq $null -or $pLogFile -eq $null)
{
    Write-Error "ERROR: No argument."
    exit
}

$RESULT_DESCRIPTION = @{ 0="Not Started"; 1="Now Proccessing ..."; 2="Success";`
                         3="Success, but Error happened"; 4="Failed"; 5="Canceled"; }

$oUpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl  
$oUpdateSession = New-Object -ComObject Microsoft.Update.Session
$oUpdateSearcher = $oUpdateSession.CreateUpdateSearcher()

$oUpdateSearcher.ServerSelection = $pUpdateType 
$oUpdateSearchResult = $null

New-Item -ItemType File -Force $pLogFile
$env:COMPUTERNAME > $pLogFile
SearchWindowsUpdate $oUpdateSearcher $oUpdateCollection > $pLogFile
$mPreLogMessage = Get-Content $pLogFile
DownloadWindowsUpdate $oUpdateSearcher $oUpdateCollection $oUpdateSession $mPreLogMessage $pLogFile
