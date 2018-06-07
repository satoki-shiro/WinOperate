#@1: Get Instance Password
#$credential = Get-Credential
#$credential.GetNetworkCredential().Password


#@2: Get Password From password file
$user = "administrator"
$credentialFile = ".\AAA.txt"
$credential = Get-Credential -Credential $user
$credential.Password | ConvertFrom-SecureString | Set-Content $credentialFile
$securePassword = Get-Content $credentialFile | ConvertTo-SecureString

# For Using remote session (etsn $hostname -cred $cred...)
$cred = New-Object System.Management.Automation.PsCredential $user, $securePassword

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

