Configuration SetupFileServer
{
    param
    (
        [string]$ShareVolume,
		[string]$ShareFolderPath,
        [string]$ShareName
    )
    
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    Node "192.168.254.170"
    {
        WindowsFeatureSet FileServerFeature
        {            
            Name = @("Windows-Server-Backup", "FS-Resource-Manager", "RSAT-FSRM-Mgmt")
            Ensure = "Present"
            IncludeAllSubFeature    = $true
        }

        File ShareDirectory
        {
            DestinationPath = $ShareFolderPath
            Type = "Directory"
            Ensure = "Present"
        }

        Script ShareDirectory
        {
            SetScript = {
                New-SmbShare -Name $using:ShareName -Path $using:ShareFolderPath -FolderEnumerationMode AccessBased `
                -FullAccess "Administrator" -ChangeAccess "Shiro"

                Grant-SmbShareAccess -Name $using:ShareName -AccountName "Everyone" -AccessRight Read

                #Disable Parent ACL
                $mDirectoryACL = Get-Acl $using:ShareFolderPath
                $mDirectoryACL.SetAccessRuleProtection($true, $true)
                $mDirectoryACL | Set-Acl $using:ShareFolderPath

                #Remove All User
                $mDirectoryACL=Get-acl $using:ShareFolderPath
                $mDirectoryACL.access | %{$mDirectoryACL.RemoveAccessRule($_)}
                Set-Acl -Path $using:ShareFolderPath -AclObject $mDirectoryACL

                # Access Rights: System.Security.AccessControl.FileSystemRights

                #SetFullControl
                $mDomainAdmin="Administrator"
                $mDirectoryACL=Get-acl $using:ShareFolderPath
                $mDomainAdminPermission=($mDomainAdmin,"FullControl","ContainerInherit, ObjectInherit","None","Allow")
                $mDomainAdminRule=New-Object System.Security.AccessControl.FileSystemAccessRule $mDomainAdminPermission
                $mDirectoryACL.SetAccessRule($mDomainAdminRule)
                $mDirectoryACL | Set-Acl $using:ShareFolderPath

                $mSystemUser="NT AUTHORITY\SYSTEM"
                $mSystemPermission=($mSystemUser,"FullControl","ContainerInherit, ObjectInherit","None","Allow")
                $mSystemRule=New-Object System.Security.AccessControl.FileSystemAccessRule $mSystemPermission
                $mDirectoryACL.SetAccessRule($mSystemRule)
                $mDirectoryACL | Set-Acl $using:ShareFolderPath

                #SetReadList
                $mDomainlUser="Shiro"
                $mDirectoryACL=Get-acl $using:ShareFolderPath
                #mDomainUserPermission=($mDomainlUser,"ListDirectory","None","None","Allow")
                $mDomainUserPermission=($mDomainlUser,"Modify","ContainerInherit, ObjectInherit","None","Allow")
                $DomainUserRule=New-Object System.Security.AccessControl.FileSystemAccessRule $mDomainUserPermission
                $mDirectoryACL.SetAccessRule($DomainUserRule)
                $mDirectoryACL | Set-Acl $using:ShareFolderPath               
            }

            TestScript = {
                Try
                { 
                    Get-SmbShare -Name $using:ShareName -ErrorAction Stop
                    return $true
                }
                Catch{
                    return $false
                }
            }
            GetScript = {@{Result = Get-SmbShare -Name $using:ShareFolderPath}}

            DependsOn = "[File]ShareDirectory"
        }

        Script EnableVolumeShadowCopy
        {
            SetScript = {
                $mWmiVol = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter = '$($using:ShareVolume):'";
                $mVolumeID = ($mWmiVol.DeviceID.SubString(10)).SubString(0,($mWmiVol.DeviceID.SubString(10)).Length-1);

                $scheduler = New-Object -ComObject Schedule.Service
                $scheduler.Connect($Env:ComputerName)

                $tskDef = $scheduler.NewTask(0);
                $tskRegInfo = $tskDef.RegistrationInfo;
                $tskSettings = $tskDef.Settings;
                $tskTriggers = $tskDef.Triggers;
                $tskActions = $tskDef.Actions;
                $tskPrincipals = $tskDef.Principal;

                # Registration Info
                $tskRegInfo.Author = "PowerShell Script";

                # Settings
                $tskSettings.DisallowStartIfOnBatteries = $false;
                $tskSettings.StopIfGoingOnBatteries = $false
                $tskSettings.AllowHardTerminate = $false;
                $tskSettings.IdleSettings.IdleDuration = "PT600S";
                $tskSettings.IdleSettings.WaitTimeout = "PT3600S";
                $tskSettings.IdleSettings.StopOnIdleEnd = $false;
                $tskSettings.IdleSettings.RestartOnIdle = $false;
                $tskSettings.Enabled = $true;
                $tskSettings.Hidden = $false;
                $tskSettings.RunOnlyIfIdle = $false;
                $tskSettings.WakeToRun = $false;
                $tskSettings.ExecutionTimeLimit = "PT259200S";
                $tskSettings.Priority = "5";
                $tskSettings.StartWhenAvailable = $false;
                $tskSettings.RunOnlyIfNetworkAvailable = $false;

                # Triggers
                $tskTrigger1 = $tskTriggers.Create(3);
                $tskTrigger2 = $tskTriggers.Create(3);

                ## Trigger 1
                $tskTrigger1.Id = "Trigger1"
                $tskTrigger1.StartBoundary = (Get-Date -format "yyyy-MM-dd")+"T07:00:00";
                $tskTrigger1.DaysOfWeek = 0x3E; # Monday - Friday - http://msdn.microsoft.com/en-us/library/windows/desktop/aa384024(v=vs.85).aspx
                $tskTrigger1.Enabled = $true;

                ## Trigger 2
                $tskTrigger2.Id = "Trigger2";
                $tskTrigger2.StartBoundary = (Get-Date -format "yyyy-MM-dd")+"T12:00:00";
                $tskTrigger2.DaysOfWeek = 0x3E; # Monday - Friday - http://msdn.microsoft.com/en-us/library/windows/desktop/aa384024(v=vs.85).aspx
                $tskTrigger2.Enabled = $true;

                # Principals (RunAs User)
                $tskPrincipals.Id = "Author";
                $tskPrincipals.UserID = "SYSTEM";
                $tskPrincipals.RunLevel = 1;

                 # Actions
                $tskActions.Context = "Author"
                $tskAction1 = $tskActions.Create(0);

                # Action 1
                $tskAction1.Path = "C:\Windows\system32\vssadmin.exe";
                $tskAction1.Arguments = "Create Shadow /AutoRetry=15 /For="+$mWmiVol.DeviceID;
                $tskAction1.WorkingDirectory = "%systemroot%\system32";

                # Configure VSS, Add scheduled task
                vssadmin Add ShadowStorage /For="$($using:ShareVolume):" /On="$($using:ShareVolume):" /MaxSize=10%;
                #$mWmiVss=[WMICLASS]"root\cimv2:win32_shadowcopy"
                #$mWmiVss.create("$($using:ShareVolume):\","ClientAccessible")

                $tskFolder = $scheduler.GetFolder("\")
                $tskFolder.RegisterTaskDefinition("ShadowCopyVolume$mVolumeID", $tskDef, 6, "SYSTEM", $null,5);
            }

            TestScript = {
                $mShadow = Get-WmiObject win32_shadowcopy
                if($mShadow.count -ne 0)
                {
                    return $true
                }
                else
                {
                    return $false
                }
            }

            GetScript = {@{Result = Get-WmiObject win32_shadowcopy}}
        }

    }
}

SetupFileServer -ShareVolume "E" -ShareFolderPath "E:\FS" -ShareName "FS"