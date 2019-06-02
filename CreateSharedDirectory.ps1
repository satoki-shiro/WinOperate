
$mDirectoryPath = "D:\FS"

#Create Shared Directory
New-Item -ItemType Directory -Name "FS" -Path $mDirectoryPath
New-SmbShare -Name "FS" -Path $mDirectoryPath -FolderEnumerationMode AccessBased `
    -FullAccess "******" -ChangeAccess "*****" -ReadAccess "*****"

#Modify Shared Access Full/Change/Read
Grant-SmbShareAccess -Name Share -AccountName nmrope -AccessRight Change

#Remove a specified account 
Revoke-SmbShareAccess -Name share -accountname nmrope

#Disable Parent ACL
$mDirectoryACL = Get-Acl $mDirectoryPath
$mDirectoryACL.SetAccessRuleProtection($true, $true)
$mDirectoryACL | Set-Acl $mDirectoryPath

#Remove All User
$mDirectoryACL=Get-acl $mDirectoryPath
$mDirectoryACL.access | %{$mDirectoryACL.RemoveAccessRule($_)}
Set-Acl -Path $mDirectoryPath -AclObject $mDirectoryACL

#SetFullControl
$mDomainAdmin="nmr\administrator"
$mDirectoryACL=Get-acl $mDirectoryPath
$mDomainAdminPermission=($mDomainAdmin,"FullControl","ContainerInherit, ObjectInherit","None","Allow")
$mDomainAdminRule=New-Object System.Security.AccessControl.FileSystemAccessRule $mDomainAdminPermission
$mDirectoryACL.SetAccessRule($mDomainAdminRule)
$mDirectoryACL | Set-Acl $mDirectoryPath

$mSystemUser="NT AUTHORITY\SYSTEM"
$mSystemPermission=($mSystemUser,"FullControl","ContainerInherit, ObjectInherit","None","Allow")
$mSystemRule=New-Object System.Security.AccessControl.FileSystemAccessRule $mSystemPermission
$mDirectoryACL.SetAccessRule($mSystemRule)
$mDirectoryACL | Set-Acl $mDirectoryPath

#SetReadList
$mDomainlUser="nmr\Domain Users"
$mDirectoryACL=Get-acl $mDirectoryPath
$mDomainUserPermission=($mDomainlUser,"ListDirectory","None","None","Allow")
$DomainUserRule=New-Object System.Security.AccessControl.FileSystemAccessRule $mDomainUserPermission
$mDirectoryACL.SetAccessRule($DomainUserRule)
$mDirectoryACL | Set-Acl $mDirectoryPath
