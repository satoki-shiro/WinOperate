

#Create Shared Directory
mkdir Share
New-SmbShare -Name "Share" -Path "D:\FS" -FolderEnumerationMode AccessBased `
    -FullAccess "******" -ChangeAccess "*****" -ReadAccess "*****"

#Modify Shared Access Full/Change/Read
Grant-SmbShareAccess -Name Share -AccountName nmrope -AccessRight Change

#Remove a specified account 
Revoke-SmbShareAccess -Name share -accountname nmrope