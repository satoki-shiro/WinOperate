

Install-WindowsFeature UpdateServices -IncludeManagementTools

new-item -Path C:\WSUS -ItemType Directory

C:\Program Files\Update Services\Tools\WsusUtil.exe postinstall CONTENT_DIR=C:\WSUS

#Check WSUS Installation Status
Invoke-BpaModel -ModelId Microsoft/Windows/UpdateServices

#Report Best Practice Analyzer 
Get-Bparesult -ModelId Microsoft/Windows/UpdateServices | select Title,Severity,Compliance | fl

#Master Server
Set-WsusServerSynchronization -SyncFromMU
#Replica Server
Set-WsusServerSynchronization -Replica "Server" -PortNumber 8530

#Start Sychronization
$wsus = get-wsusserver
$conf = $wsus.getconfiguration()

$langCollection = New-Object System.Collections.Specialized.StringCollection
$langCollection.addrange(("en","ja"))

$conf.AllUpdateLanguagesEnabled = $false 
$conf.SetEnabledUpdateLanguages($langCollection) 
$conf.Save()

$sub = $wsus.getsubscription()
$sub.StartSynchronizationForCategoryOnly()

While ($sub.GetSynchronizationStatus() -ne ‘NotProcessing’) {
    Write-Host “.” -NoNewline
    Start-Sleep -Seconds 5
}

#Configure the Classifications
Get-WsusProduct | where-Object {$_.Product.Title -in ('Office','Windows')} | Set-WsusProduct
Get-WsusClassification | Where-Object {
    $_.Classification.Title -in (
    'Update Rollups',
    'Security Updates',
    'Critical Updates',
    'Service Packs',
    'Updates')
} | Set-WsusClassification

#Get Current Product
$wsus.GetSubscription().GetUpdateCategories() | Select-Object Title, Description
$wsus.getsubscription().getupdateclassifications() | select Title, Description

#Configure Synchronizations
$subscription.SynchronizeAutomatically=$true

#Set synchronization scheduled for midnight each night
$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
$subscription.NumberOfSynchronizationsPerDay=1
$subscription.Save()

#Kick off a synchronization
$subscription.StartSynchronization()