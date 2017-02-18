#@1: Get Instance Password
#$credential = Get-Credential
#$credential.GetNetworkCredential().Password


#@2: Get Password From password file
$credentialFile = ".\AAA.txt"
$credential = Get-Credential
$credential.Password | ConvertFrom-SecureString | Set-Content $credentialFile
$securePassword = Get-Content $credentialFile | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

