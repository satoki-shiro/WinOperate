Configuration ActiveDirectoryServer
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node 192.168.254.210
    {
        WindowsFeature AddDomainService
        {
            Name = "AD-Domain-Services"
            Ensure = "Present"
        }
    }
}

ActiveDirectoryServer