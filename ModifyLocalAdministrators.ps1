Param ([string] $MODE)

$HOMEDIR=Split-Path -Parent ($MyInvocation.MyCommand.Path)
$PCLIST="$($HOMEDIR)\LocalAdminPCList.csv"

$mLocalAdminFile="$($HOMEDIR)\LocalAdmin.lst"
$mLogFile="$($HOMEDIR)\ModifyLocalAdministrators.log"

Write-Output "INFO: Start Task" > $mLogFile

If((Test-Path($PCLIST)) -eq $false)
{
    Write-Output "ERROR: There is no user for installation." > $mLogFile
}

$mList = Import-Csv -Encoding Default $PCLIST

$mNowDateObject = Get-Date
$mStartTimeObject=$null
$mEndTimeObject=$null

$mList | %{
    if($_.PC -eq $env:COMPUTERNAME)
    {
        $mStartTimeObject = [DateTime]$_.StartTime
        $mEndTimeObject = [DateTime]$_.EndTime        
    }
}

$mTargetUser = $null

Write-Output $MODE >> $mLogFile

Switch($MODE)
{
    "Add"
    {
        (query user | findstr "Active") -cmatch "^\s(?<activeuser>[a-zA-Z_0-9-]+)\s+\w+" | Out-Null
        $mTargetUser = $matches.activeuser

        if($mTargetUser -eq $null)
        {
            Write-Output "ERROR: There is no Active User" > $mLogFile
            exit
        }

        if(((Test-Path $mLocalAdminFile) -eq $true) -and ($mNowDateObject -ge $mStartDateObject))
        {   
            $group = [ADSI]"WinNT://$($env:COMPUTERNAME)/Administrators,group"
            $group.Add("WinNT://$($env:USERDOMAIN)/$($mTargetUser),user")
            Write-Output $mTargetUser > $mLocalAdminFile
            Write-Output "INFO: Successful for Adding $($mTargetUser) to Administrators Group." > $mLogFile

            schtasks /Delete /TN "AddLocalAdministratorsOnTime" /F
            schtasks /Delete /TN "AddLocalAdministratorsOnLogon" /F
        }
                
    }

    "Delete"
    {
        if(((Test-Path $mLocalAdminFile) -eq $true) -and ($mNowDateObject -ge $mEndDateObject))
        {   
            $mTargetUser = Get-Content $mLocalAdminFile
            $group = [ADSI]"WinNT://$($env:COMPUTERNAME)/Administrators,group"
            $group.Remove("WinNT://$($env:USERDOMAIN)/$($mTargetUser),user")
    
            Write-Output "INFO: Successful for Deleted $($mTargetUser) from Administrators Group." > $mLogFile

            schtasks /Delete /TN "DeleteLocalAdministratorsOnTime" /F
            schtasks /Delete /TN "DeleteLocalAdministratorsOnLogon" /F

            Remove-Item $mLocalAdminFile
        }
    }
}
