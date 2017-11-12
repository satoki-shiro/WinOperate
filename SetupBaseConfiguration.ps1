########################################################
# FileName: SetupBaseConfiguration.ps1
# Author: Shiro
# Update: Apr. 23, 2017
########################################################

function SetHostName(){
    Rename-Computer -NewName $conf.system.hostname
}

function JoinDomain(){
    $domain = $conf.system.domain.domainname
    $password = $conf.system.domain.password | ConvertTo-SecureString -asPlainText -Force
    $domainAccount = "$domain\$conf.system.domain.account" 
    $credential = New-Object System.Management.Automation.PSCredential($domainAccount,$password)
    Add-Computer -DomainName $domain -Credential $credential
}

function SetNetworkInterface(){
    Get-NetAdapterBinding | ? {$_.DisplayName -match "ipv6" } | Set-NetAdapterBinding -Enabled $false
    Get-NetAdapterBinding | ? {$_.DisplayName -match "qos" } | Set-NetAdapterBinding -Enabled $false
}

function EnableRemoteDesktop(){
    (Get-WmiObject Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1,1) | Out-Null
    #(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) | Out-Null
    Get-NetFirewallRule -DisplayName "リモート デスクトップ*" | ?{$_.Profile -match "Domain"} | Set-NetFirewallRule -Enabled true
    New-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fSingleSessionPerUser" -Value 0 -PropertyType DWORD -Force | Out-Null
}

function SetFirewall(){
    Set-NetFirewallProfile -All -NotifyOnListen true
    Get-NetFirewallRule | ?{$_.profile -eq "Domain"} | Enable-NetFirewallRule
}

function SetWindowsUpdate(){
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 2
}

function InstallWindowsPatch(){
    Get-ChildItem -Path "$conf.system.updatedir" -recurse -include "*.cab" | % { dism /online /add-package=$_.FullName /norestart }
}

########################################################
# Entry Point
########################################################

Write-Output "@STEP 0 - Load configuration ..."
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
[String]$confFile = Join-Path $HOMEDIR "ServerBaseConf.xml"
[String]$stepFile = Join-Path $HOMEDIR "Step.conf"
[Xml]$confDoc = $null

try{
    [Xml]$confDoc = Get-Content -Path $confFile -ErrorAction Stop
}catch{
    Write-Output "ERROR: Cannot load configuration file!"
    Write-Output $Error[0]
    exit
}
[Xml.XmlElement]$conf = $confDoc.config
Write-Output "@STEP 0 - Done!"

$currentStep = Get-Content $stepFile
switch($currentStep){
    "0" {
        Write-Output "@STEP 1 - Set Computer Name"
            SetHostName
        Write-Output 1 > $stepFile
        Write-Output "@STEP 1 - Done!"
        Restart-Computer
    }

    "1" {
        Write-Output "@STEP 2 - Join domain"
            JoinDomain
        Write-Output 2 > $stepFile
        Write-Output "@STEP 2 - Done!"
        Restart-Computer
    }

   "2" {
        $computerSystem = Get-WmiObject Win32_ComputerSystem
        if( $ComputerSystem.PartOfDomain -eq $false ){
            Write-Host "WARN: Failed to join that domain!"
            Write-Output 1 > $stepFile
            exit
        }

        Write-Output "@STEP 3 - Set Basic configuration"
            SetNetworkInterface
            EnableRemoteDesktop
            SetFirewall
            SetWindowsUpdate
            InstallWindowsPatch
        Write-Output 3 > $stepFile
        Write-Output "@STEP 3 - Done!"
    }

}



# Only DOW
# 1. Change Hostname
# wmic computersystem where name="%COMPUTERNAME%" call rename name="NEW-NAME"

