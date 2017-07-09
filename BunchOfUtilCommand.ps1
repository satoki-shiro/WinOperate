
# To copy file from local to remote server
$hostName = ""
$cred = ""
$session = New-PSSession $hostName -Credential $cred
Copy-Item -Path "Selected File Path" -Destination "C:\..." -ToSession $session