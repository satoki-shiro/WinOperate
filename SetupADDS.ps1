﻿function SetupPrimaryADDS
{
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    Install-ADDSForest -DomainName sixteen.contoso.ad
    Get-Service adws,kdc,netlogon,dns
    Get-smbshare
}

function DemoteADDS
{
    Import-Module ADDSDeployment
Uninstall-ADDSDomainController `
-DemoteOperationMasterRole:$true `
-IgnoreLastDnsServerForZone:$true `
-LastDomainControllerInDomain:$true `
-RemoveApplicationPartitions:$true `
-Force:$true 

Import-Module ActiveDirectory
Uninstall-ADDSDomainController -IgnoreLastDCInDomainMismatch `
-RemoveApplicationPartitions 
}


$errorLogs = ""

Install-WindowsFeature -name AD-Domain-Services –IncludeManagementTools
Test-ADDSDomainControllerInstallation -DomainName nmr.local -InstallDns `
    -Credential (Get-Credential nmr\administrator) `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "******" -asplaintext -force) `
    | ? { $_.Status -ne "Success" } > $errorLogs

if((cat $errorLogs) -ne $null){
    Write-Output "ERROR: This server is unsatisfied with ADDSDomainContoroller"
    exit
} 

Install-ADDSDomainController –domainname nmr.local `
    -credential (get-credential nmr\administrator) `
    -InstallDNS:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "******" -asplaintext -force) `
    -ReplicationSourceDC NMR-DC.nmr.local


#Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString "*****" -asplaintext -force)


