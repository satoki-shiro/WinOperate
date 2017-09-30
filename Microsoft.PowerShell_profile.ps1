$mGlobalProfile = "C:\TEST\GlobalProfile.ps1"
if (Test-Path $mGlobalProfile )
{
    .$mGlobalProfile 
}