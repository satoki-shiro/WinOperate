######################################################
#
# FileName:    CreateFolder
# Update:      
# Author:      
# Description:  
# 
######################################################

# => 定義ファイル読み込み
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
[String]$CONFFILE = Join-Path $HOMEDIR "FileServerConf.xml"
[Xml]$mConfDoc = $null

try{
    [Xml]$mConfDoc = Get-Content -Path $CONFFILE -ErrorAction Stop
}catch{
    Write-Error $Error[0]
    exit
}
[Xml.XmlElement]$mConf = $mConfDoc.configuration


# => 説明
$mDescription = @"
######################################################
#
#　～用の設定スクリプトです。
#　表示されるメッセージに従い、所定の値を入力してください。
# 
######################################################

"@
Write-Host $mDescription


# => メールアドレス確認  
$mMailAddress = Read-Host "対象者のメールアドレスを入力してください"
$rUserInfo = Get-ADUser -Filter * -SearchBase "DC=nmr,DC=local" -Property mail | `
?{ $_.mail -eq $mMailAddress }

If($rUserInfo -eq $null)
{
    Write-Warning "入力したメールアドレスは存在しません。"
    exit
}
Write-Host "`n"


# => サーバ情報入力 
$mServers = $mConf.server_list.server | ?{$_.share_private_dir.type -eq 2} |`
 %{ "[$($_.id.padleft(2))] $($_.hostname)" }
$mServerDescription = @"
=================================================
$($mServers -Join "`n")
=================================================
対象となるサーバを上記から数字で選択してください
"@

$mServerId = Read-Host $mServerDescription
$rServer = $mConf.server_list.server | ?{$_.id -eq $mServerId}
$rRemoteDir = $rServer.share_private_dir.InnerText
Write-Host "`n"


# => 処理実行 
$mAdminUser = $mConf.init_info.remote_user
$mRemotePrivateDir = "$($rRemoteDir)\$($rUserInfo.SamAccountName) $($rUserInfo.GivenName)"

$mChoiceTitle = "【　ディレクトリ作成　】"
$mChoiceMessage = @"
サーバ「$($rServer.hostname)」に
ディレクトリ「$($mRemotePrivateDir)」を作成します。処理を実行しますか？
"@

$mYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "実行"
$mNO = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "終了"

$mChoiceOptions = [System.Management.Automation.Host.ChoiceDescription[]]($mYes, $mNo)
$mChoiceResult = $host.ui.PromptForChoice($mChoiceTitle, $mChoiceMessage, $mChoiceOptions, 0) 

switch ($mChoiceResult)
{
    0 
    {
        try{
            $mSession = New-PSSession -ComputerName $rServer.hostname -Credential $mAdminUser

            Invoke-Command -Session $mSession { New-Item $args[0] -ItemType Directory | Out-Null } `
                     -ArgumentList $mRemotePrivateDir -ErrorAction Stop

            Invoke-Command -Session $mSession {
                        $aclObject = Get-Acl $args[0]
                        $mAclParam = @($args[1], "Modify", "ContainerInherit, ObjectInherit", "None","Allow") 
                        $mRule = New-Object System.Security.AccessControl.FileSystemAccessRule $mAclParam
                        $aclObject.AddAccessRule($mRule)
                        Set-Acl $args[0] -AclObject $aclObject ` 
                } -ArgumentList $mRemotePrivateDir,$rUserInfo.SamAccountName -ErrorAction Stop
            
            Write-Output "ディレクトリ作成が完了しました。`n"

        }catch{
            Write-Error $Error[0]
            exit
        }
    }
    
    1 
    {
        Write-Host "処理を終了します。"
        exit
    }
}
