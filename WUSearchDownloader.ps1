function SearchWindowsUpdate([__ComObject]$UpdateSearcher, [__ComObject]$UpdateCollection, $LogFile)
{
    $mHostName = $env:COMPUTERNAME
    $mResultOfSearch = $UpdateSearcher.Search("IsInstalled = 0 and IsHidden = 0")

    $mResultDescription = $RESULT_DESCRIPTION[$mResultOfSearch.ResultCode]
    
    $mUpdateItemCount = $mResultOfSearch.updates.count
    If($mUpdateItemCount -eq 0)
    {
        Write-Output "$($mHostName)`tEnd Search`t0`t0`t$($mResultDescription)" > $LogFile
        Return
    }

    $mUpdateItemSize = 0
    ForEach($updateItem in $mResultOfSearch.updates)
    {
        $mUpdateItemSize += $updateItem.MaxDownloadSize
        $UpdateCollection.Add($updateItem) | Out-Null
    }
    Write-Output "$($mHostName)`tEnd Search`t$($mUpdateItemCount)`t$([Math]::Round($mUpdateItemSize/(1024*1024),1))MB`t$($mResultDescription)" > $LogFile
    
 }

function DownloadWindowsUpdate([__ComObject]$UpdateSearcher, [__ComObject]$UpdateCollection, [__ComObject]$UpdateSession, $LogFile, $ListFile)
{
    $mDownloadCount = 0
    $mPreLogMessage = Get-Content $LogFile

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
				Write-Output "$($mPreLogMessage)`tEnd Download`t0`tERROR:You cannot perform this task due to your privilege." > $LogFile
			} 
            Return
        }

        If($mDownloadResult.ResultCode -eq 2){
            $mDownloadCount++
            Write-Output "$($downloadItem.Identity.UpdateID)`t$($downloadItem.InstallationBehavior.RebootBehavior)`t$($downloadItem.Title)" >> $ListFile
        }

        Write-Output "$($mPreLogMessage)`tStart Download`t$($mDownloadCount) / $($UpdateCollection.count)" > $LogFile
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
        Write-Output "$($mPreLogMessage)`tEnd Download`t$($mDownloadCount)`tWARN:Failed to download some files. Reboot Flag is $($mRequiredReboot)" > $LogFile
    }
    else
    {
        Write-Output "$($mPreLogMessage)`tEnd Download`t$($mDownloadCount)`tINFO:Downloading is completed. Reboot Flag is $($mRequiredReboot)" > $LogFile
    }
}

##########################################
# 
#  ENTRY POINT
#
##########################################

$pUpdateType = $Args[1]
$pLogFile = $Args[2]
$pListFile = $Args[3]

If($pUpdateType -eq $null -or $pLogFile -eq $null)
{
    Write-Error "ERROR: No argument."
    exit
}

$RESULT_DESCRIPTION = @{ 0="Not Started"; 1="Now Proccessing ..."; 2="Success";`
                         3="Success, but Error happened"; 4="Failed"; 5="Canceled"; }

$oUpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl  
$oUpdateSession = New-Object -ComObject Microsoft.Update.Session

#$oUpdateSearcher = New-Object -ComObject Microsoft.Update.Searcher  
$oUpdateSearcher = $oUpdateSession.CreateUpdateSearcher()

$oUpdateSearcher.ServerSelection = $pUpdateType 
$oUpdateSearchResult = $null

New-Item -ItemType File -Force $pLogFile
Write-Output "$($env:COMPUTERNAME)`tStart Search" > $pLogFile
SearchWindowsUpdate $oUpdateSearcher $oUpdateCollection $pLogFile

New-Item -ItemType File -Force $pListFile
DownloadWindowsUpdate $oUpdateSearcher $oUpdateCollection $oUpdateSession $pLogFile $pListFile
