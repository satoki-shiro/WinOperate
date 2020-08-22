Configuration SetupBasic
{
    
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    Node "192.168.254.170"
    {
        Package Browser
        {
            Ensure = "Present"
            Name = "Microsoft Edge"
            Path = "C:\Setup\MicrosoftEdgeEnterpriseX64.msi"
            ProductId= "3196C85D-CFB0-3E5B-A592-0322692C2140"
        }

        #Package Sakura
        #{
        #    Ensure = "Present"
        #    Name = "sakura editor(サクラエディタ)"
        #    Path = "C:\Setup\sakura_install2-4-1-2849-x86.exe"
        #    ProductId = ""
        #    Arguments = "/VERYSILENT /SP-" # args for silent mode
        #}

         Script installCubePDFUtility 
        {
	        GetScript = 
            {
		        return @{ Result = Get-ChildITem "C:\Setup\cubepdf-utility-0.5.7b-x64.exe" }
	        }

	        SetScript = 
            {
		        $mExec = "C:\Setup\cubepdf-utility-0.5.7b-x64.exe"
		        $mArguments = "/VERYSILENT /SP-"
		        $null = start-process $mExec $mArguments 
	        }

	        TestScript = 
            {
		        Return (Test-Path "C:\Setup\cubepdf-utility-0.5.7b-x64.exe")
	        }
        }
    }
}


SetupBasic