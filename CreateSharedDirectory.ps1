

#Create Shared Directory
mkdir Share
New-SmbShare -Name "Share" -Path "D:\FS" -FolderEnumerationMode AccessBased `
    -FullAccess "******" -ChangeAccess "*****" -ReadAccess "*****"

#Modify Shared Access
Grant-SmbShareAccess -Name Share -AccountName nmrope -AccessRight Change