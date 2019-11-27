Configuration WebSiteConfigInstall
{
    Node localhost
    {
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }
    }
}

WebSiteConfigInstall