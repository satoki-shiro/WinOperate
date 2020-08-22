Configuration SetupDomainController
{
    param
    (
        [PSCredential]$DomainCredential,
        [string]$DomainName,
        [string]$Pdc
    )
    
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    Node "192.168.254.180"
    {
        

        WindowsFeatureSet DomainController
        {            
            Name = @("AD-Domain-Services", "RSAT-AD-Tools", "RSAT-DNS-Server")
            Ensure = "Present"
            IncludeAllSubFeature    = $true
        }        

        Script InstallDomainController
        {
            PsDscRunAsCredential = $DomainCredential

            SetScript = {
                $sourcePDC = "$($using:Pdc).$($using:DomainName)"
                $installResult=Install-ADDSDomainController –DomainName $using:DomainName `
                    -InstallDNS:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "Lotus321" -asplaintext -force) `
                    -ReplicationSourceDC $sourcePDC -SysvolPath "C:\Windows\SYSVOL" -LogPath "C:\Windows\NTDS" -DatabasePath "C:\Windows\NTDS"

                $installResult | Export-Csv -Encoding Default -NoTypeInformation "C:\ADDSDomainControllerInstallation.log"
            }

            TestScript = {                
                $testResult=Test-ADDSDomainControllerInstallation -DomainName $using:DomainName `
                    -InstallDns -SafeModeAdministratorPassword (ConvertTo-SecureString "Lotus321" -asplaintext -force)
                
                $testResult | Export-Csv -Encoding Default -NoTypeInformation "C:\Test-ADDSDomainControllerInstallation.log"

                $testResult | %{
                    if($_.Status -ne "Success")
                    {
                        Write-Error $_.Message
                        return $false
                    }
                }

                $mOSInfo = Get-WMIObject -Namespace "root/CIMV2" -Query "SELECT * FROM Win32_OperatingSystem"
                If($mOSInfo.ProductType -ne 2)
                {
                    return $false
                }
                else
                {
                    return $true
                }
            }
            GetScript = {@{Result = Get-ADDomain $DomainName}}

            DependsOn = "[WindowsFeatureSet]DomainController"
        }

    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName = '192.168.254.180'
            PSDscAllowDomainUser = $true
            PSDscAllowPlainTextPassword = $true
        }
    )
}


$cred = Get-Credential -UserName nmr\administrator -Message "Please input password"
SetupDomainController -DomainCredential $cred -DomainName "nmr.local" -Pdc "NMRDC01" -ConfigurationData $cd