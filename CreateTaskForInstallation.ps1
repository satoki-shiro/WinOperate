$HOMEDIR=Split-Path -Parent ($MyInvocation.MyCommand.Path)
$EXEFILE="$($HOMEDIR)\ModifyLocalAdministrators.ps1"
$PCLIST="$($HOMEDIR)\LocalAdminPCList.csv"

$ADDTASK="$($HOMEDIR)\AddLocalAdministrators.ps1"
$DELTASK="$($HOMEDIR)\DeleteLocalAdministrators.ps1"

If((Test-Path($PCLIST)) -eq $false)
{
    Write-Output "ERROR: There is no user for installation."
}

$mList = Import-Csv -Encoding Default $PCLIST
$mStartTime=$null
$mEndTime=$null

$mList | %{
    if($_.PC -eq $env:COMPUTERNAME)
    {
        $mStartTime = $_.StartTime
        $mEndTime = $_.EndTime        
    }
}

$mStartDateObject = [Datetime]$mStartTime
$mTaskStartDate = $mStartDateObject.ToString("yyyy/MM/dd")
$mTaskStartTime = $mStartDateObject.ToString("HH:mm:ss")

$mEndDateObject = [Datetime]$mEndTime
$mTaskEndDate = $mEndDateObject.ToString("yyyy/MM/dd")
$mTaskEndTime = $mEndDateObject.ToString("HH:mm:ss")

schtasks /Create /TN "AddLocalAdministratorsOnTime" /TR "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File $($EXEFILE) -Mode Add"`
    /SD $mTaskStartDate /ST "$($mTaskStartTime)" /ET "23:59" /RI "10" /SC MONTHLY /RU SYSTEM /RL HIGHEST /F

schtasks /Create /TN "AddLocalAdministratorsOnLogon" /TR "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File $($EXEFILE) -Mode Add" `
    /SC ONLOGON /RU SYSTEM /RL HIGHEST /F

schtasks /Create /TN "DeleteLocalAdministratorsOnTime" /TR "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File $($EXEFILE) -Mode Delete" `
    /SD $mTaskEndDate /ST "$($mTaskEndTime)" /ET "23:59" /RI "10" /SC MONTHLY /RU SYSTEM /RL HIGHEST /F

schtasks /Create /TN "DeleteLocalAdministratorsOnLogon" /TR "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File $($EXEFILE) -Mode Delete" `
    /SC ONLOGON /RU SYSTEM /RL HIGHEST /F

