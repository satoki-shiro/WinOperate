
function GetDomainControllerConfiguration($computerName){
    invoke-command $computerName -ScriptBlock{
        $hostName = hostname

        # Get Configuration
        $dc = Get-ADDomainController $hostName
        Write-Output "ドメイン `t $($dc.domain)"
        Write-Output "フォレスト `t $($dc.forest)"
        Write-Output "ホスト名 `t $($dc.hostName)"
        Write-Output "グローバルカタログ `t $($dc.IsGlobalCatalog)"
        Write-Output "読み取り専用 `t $($dc.IsReadOnly)"
        Write-Output "NTDS設定オブジェクト `t $($dc.NTDSSettingsObjectDN)"
        Write-Output "パーティション `t $($dc.Partitions)"
        Write-Output "サイト `t $($dc.Site)"
        Write-Output "LDAPポート `t $($dc.LdapPort)"
        Write-Output "SSLポート `t $($dc.SSlPort)"

        # Get Directory
        $machineReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine",$hostName)
        $ntdsKeys = $machineReg.opensubkey("SYSTEM\CurrentControlSet\Services\NTDS\Parameters")
        $netlogonKeys = $machineReg.opensubkey("SYSTEM\CurrentControlSet\Services\Netlogon\Parameters")

        $databaseFilePath = $ntdsKeys.getvalue("DSA Database file")
        $logFilePath = $ntdsKeys.getvalue("Database log files path")
        $sysvolFilePath = $netlogonKeys.getvalue("SysVol")

        Write-Output "データベースのフォルダー `t $databaseFilePath"
        Write-Output "ログ ファイルのフォルダー `t $logFilePath"
        Write-Output "SYSVOL フォルダー `t $sysvolFilePath"

    }
}

$domainControllers = Get-ADDomainController -Filter *
foreach($domainController in $domainControllers){
    $outFile = $domainController.Name + ".tsv"
    GetDomainControllerConfiguration($domainController.Name) > $outFile
}
