$checkDateTime = Get-Date -Format "u"
Write-Output "[$($checkDateTime)] Start checking Active Directory Status"

Write-Output "@STEP1: ====== Check NTDS Replication Status"
Write-Output "ServerName`tLastReplicationAttempt`tLastReplicationResult`tLastReplicationSuccess`tReplicationPartner"
Get-ADReplicationPartnerMetadata -target * | 
%{ 
    Write-Output "$($_.Server)`t$($_.LastReplicationAttempt)`t$($_.LastReplicationResult)`t$($_.LastReplicationSuccess)`t$($_.Partner)"
}
Write-Output "@STEP1: ====== Done!`n"


Write-Output "@STEP2: ====== Check NTDS Replication Failed log"
Get-ADReplicationFailure nmr.local
Write-Output "@STEP2: ====== Done!`n"


$SYSVOL_REP_STATUS=@{0="Uninitialized"; 1="Initialized"; 2="Initial Sync"; 3="Auto Recovery"; 4="Normal"; 5="In Error"}
Write-Output "@STEP3: ====== Check SYSVOL DFSR Status"
Write-Output "MemberName`tReplicationGroupName`tReplicatedFolderName`tStatus"

$controllers = Get-ADDomainController -Filter *
foreach ($controller in $controllers){
    $replGroup = Get-WmiObject -ComputerName $controller.hostName `
        -Namespace "root\MicrosoftDFS" `
        -Query "SELECT * FROM dfsrreplicatedfolderinfo WHERE replicatedfoldername='SYSVOL share'"
    Write-Output "$($replGroup.MemberName)`t$($replGroup.ReplicationGroupName)`t$($replGroup.ReplicatedFolderName)`t$($SYSVOL_REP_STATUS[[int]$replGroup.State])"
}
Write-Output "@STEP3: ====== Done!`n"


Write-Output "@STEP4: ====== Check NTP Status"
Write-Output "ServerName`tTimeSource`tLastSyncDateTime`tLastSyncError`tOffsetLastSync"

$monitorTemp = w32tm /monitor /domain:$($controllers[0].Domain) /nowarn
$monitorResult = ($monitorTemp[9..$monitorTemp.length]).Trim()

foreach ($controller in $controllers){
    $timeStatus = w32tm /query /computer:$($controller.HostName) /status /verbose
    $timeSource = ((($timeStatus | sls "ソース: ").ToString()).Split(":")[1]).Trim()
    $lastSyncDateTime = (($timeStatus | sls "最終正常同期時刻: ").ToString()).Split(" ")
    $lastSyncError = ((($timeStatus | sls "最終同期エラー: ").ToString()).Split(":")[1]).Trim()
    
    $ntpOffsetTemp = (($monitorResult | sls "^$($controller.HostName)" -Context 0,2).ToString()).Split("`n")
    $ntpOffsetTime = $ntpOffsetTemp[2].Split(":")[1].Trim().Split(" ")[0]

    Write-Output "$($controller.HostName)`t$($timeSource)`t$($lastSyncDateTime[1]) $($lastSyncDateTime[2])`t$($lastSyncError)`t$($ntpOffsetTime)" 
    
}
Write-Output "@STEP4: ====== Done!`n"


Write-Output "@STEP5: ====== Check FSMO Roles"
Get-ADDomainController -Filter * | % {if($_.OperationMasterRoles -ne "" )` 
    {Write-Output "Host Name: $($_.HostName)"; Write-Output "Host Roles: $($_.OperationMasterRoles)"}}
Write-Output "@STEP5: ====== Done!`n"


$checkDateTime = Get-Date -Format "u"
Write-Output "[$($checkDateTime)] End checking Active Directory Status"
