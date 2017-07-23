function InstallWindowsUpdate($LogFile, $InstallListFile)
{
    $mHostName = $env:COMPUTERNAME

    $mUpdateSession = New-Object -ComObject Microsoft.Update.Session
    $mUpdateSearcher = $mUpdateSession.CreateUpdateSearcher()

    $mRequiredReboot = "NO"
    $mInstallCount = 0
    $mInstallArray = (Get-Content $InstallListFile) -as [string[]]

    foreach($installItem in $mInstallArray)
    {
        $updateID = $($installItem).split("`t")[0]
        $resultOfSearch = $mUpdateSearcher.Search("UpdateID = '$($updateID)'")
        
        $trgUpdateItem = $resultOfSearch.updates.Item(0)

        If($trgUpdateItem.InstallationBehavior.RebootBehavior -gt 0) { $mRequiredReboot = "YES" }

        If($trgUpdateItem.IsInstalled -eq $True)
        {
            $mInstallCount++
            continue; 
        }

        If($trgUpdateItem.IsDownloaded -eq $False) { continue; }

        $tempCollection = New-Object -ComObject Microsoft.Update.UpdateColl  
        $tempCollection.Add($trgUpdateItem) | Out-Null

        $installer = $mUpdateSession.CreateUpdateInstaller()
        $installer.Updates = $tempCollection

        Try
        {
            $mInstallResult = $installer.Install()
        }
        Catch
        {
            If($_ -match "HRESULT: 0x80240044")
			{
				Write-Output "$($mHostName)`tEnd Install`t0`tERROR:You cannot perform this task due to your privilege." > $LogFile
			} 
            Return
        }

        If($mInstallResult.ResultCode -eq 2){
            $mInstallCount++
        }

        Write-Output "$($mHostName)`tStart Install`t$($mInstallCount) / $($mInstallArray.Length)" > $LogFile
        
    }

    If($mInstallArray.Length -gt $mInstallCount)
    {
        Write-Output "$($mHostName)`tEnd Install`t$($mInstallCount)`tWARN:Failed to install some files. Reboot Flag is $($mRequiredReboot)" > $LogFile
    }
    else
    {
        Write-Output "$($mHostName)`tEnd Install`t$($mInstallCount)`tINFO:Installing is completed. Reboot Flag is $($mRequiredReboot)" > $LogFile
    }
}

##########################################
# 
#  ENTRY POINT
#
##########################################

$pLogFile = $Args[1]
$pInstallListFile = $Args[2]

If($pLogFile -eq $null -or $pInstallListFile -eq $null)
{
    Write-Error "ERROR: No argument."
    exit
}

$RESULT_DESCRIPTION = @{ 0="Not Started"; 1="Now Proccessing ..."; 2="Success";`
                         3="Success, but Error happened"; 4="Failed"; 5="Canceled"; }

New-Item -ItemType File -Force $pLogFile
Write-Output "$($env:COMPUTERNAME)`tStart Install" > $pLogFile

InstallWindowsUpdate $pLogFile $pInstallListFile
