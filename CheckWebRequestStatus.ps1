####################################################
# FileName:       CheckWebRequestStatus.ps1
# Authority:      NMR
# Update:         Jun. 2, 2018
# Param:          URI ex) http://test.com 
####################################################

Param ([string] $URI);

If($URI -notmatch "^(http|https)://.*")
{
    Write-Output -1;
    exit;
}

$mWebResponse = $null;

try{
   $mWebResponse = Invoke-WebRequest -Uri $URI -Method Get;
   Write-Output $mWebResponse.StatusCode;
}
catch
{
   Write-Output $_.Exception.Response.StatusCode.Value__;
}