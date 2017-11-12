######################################################
#
# FileName:    SetUserGroup
# Update:      
# Author:      
# Description:  
# 
######################################################

# => 定義ファイル読み込み
$HOMEDIR = (Split-Path $MyInvocation.MyCommand.Path -parent)
[String]$CONFFILE = Join-Path $HOMEDIR "DomainControllerConf.xml"
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
$mUserID = Read-Host "対象者のユーザーIDを入力してください"
$rUserInfo = Get-ADUser -Filter "SamAccountName -eq '$($mUserID)'"
If($rUserInfo -eq $null)
{
    Write-Warning "入力したユーザーIDは存在しません。"
    exit
}
Write-Host "`n"


# => サーバ情報入力 
$mServers = $mConf.server_list.server | %{ "[$($_.id.padleft(2))] $($_.hostname)" }
$mServerDescription = @"
=================================================
$($mServers -Join "`n")
=================================================
対象となるサーバを上記から数字で選択してください
"@

$mServerId = Read-Host $mServerDescription
$rServer = $mConf.server_list.server | ?{$_.id -eq $mServerId}
Write-Host "`n"


# => 対象グループ入力 
$mUserGroup = Read-Host "対象となるユーザーグループを入力してください"
$rUserGroup = Get-ADGroup  -Filter "name -eq '$($mUserGroup)'"
If($rUserGroup -eq $null)
{
    Write-Warning "入力したユーザーグループは存在しません"
    exit
}
Write-Host "`n"


# => 処理実行
$mAdminUser = $mConf.init_info.remote_user
$mChoiceTitle = "【　ユーザーグループ設定　】"
$mChoiceMessage = @"
サーバ「$($rServer.hostname)」で
ユーザー「$($rUserInfo.SamAccountName)」を
ユーザーグループ「$($rUserGroup.SamAccountName)」に追加します。処理を実行しますか？
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

            Invoke-Command -Session $mSession { 
                Add-ADGroupMember $args[1] -Members $args[0] 
                } -ArgumentList $rUserInfo.SamAccountName, $rUserGroup.SamAccountName -ErrorAction Stop

            Write-Output "ユーザーグループへのユーザー追加が完了しました。`n"

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
