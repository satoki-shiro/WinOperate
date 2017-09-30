$mFileName ="$($env:UserName)_" + (Get-Date -Format 'yyyyMMddhhmmss') + ".log"
$mFilePath = "C:\TEST\" + $mFileName + "\"
Start-Transcript -Path $mFilePath -NoClobber