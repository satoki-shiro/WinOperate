####################################################
# FileName:       GetServerResourceFiles.ps1
# Authority:      NMR
# Update:         Jun. 2, 2018
# Param:          Directory path for saving resource files 
####################################################

Param ([string] $SAVEDIR);

If($SAVEDIR -eq "")
{
    $SAVEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
}
else
{
    If(-not(Test-Path($SAVEDIR)))
    {
        Write-Error "ERROR: That directory is not found."
        exit
    }
}

# Define Const values
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)

# Load configuration file
[String]$CONFFILE = Join-Path $HOMEDIR "ServerResourceList.xml"
[Xml]$mConfDoc = $null

try{
    [Xml]$mConfDoc = Get-Content -Path $CONFFILE -ErrorAction Stop
}catch{
    Write-Output "ERROR: Cannot load configuration file!"
    Write-Output $Error[0]
    exit
}

[Xml.XmlElement]$mConf = $mConfDoc.configuration
$mCred = Get-Credential -Credential Administrator

foreach($resource in $mConf.resource_list.resource)
{
    $mTemplateFile = $resource.targetfile
    $mExecFile = $resource.execfile
    $mCurDate = (Get-Date).AddDays(-1).ToString("yyyyMMdd")

    foreach($server in $resource.server_list.server)
    {
        $mResourceFile = ($mTemplateFile -replace "%HOSTNAME%", $server.hostname) -replace "%YYYYMMDD%", $mCurDate
        If($mResourceFile -eq "")
        {
            Write-Output "WARN: No Resource File."
            Continue;
        }

        $mSession = New-PSSession $server.hostname -Credential $mCred
        Invoke-Command -Session $mSession { cmd /c $args[0] } -ArgumentList $mExecFile
        Copy-Item -Destination $SAVEDIR -Path $mResourceFile -FromSession $mSession
        Remove-PSSession $mSession
    }
}

