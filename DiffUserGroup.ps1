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


# => ユーザーID①確認  
$mUser1ID = Read-Host "比較対象１のユーザーIDを入力してください"
$rUser1Info = Get-ADUser -Filter "SamAccountName -eq '$($mUser1ID)'" -Property *
If($rUser1Info -eq $null)
{
    Write-Warning "入力したユーザーIDは存在しません。"
    exit
}


# => ユーザーID②確認  
$mUser2ID = Read-Host "比較対象２のユーザーIDを入力してください"
$rUser2Info = Get-ADUser -Filter "SamAccountName -eq '$($mUser2ID)'" -Property *
If($rUser2Info -eq $null)
{
    Write-Warning "入力したユーザーIDは存在しません。"
    exit
}
Write-Host "`n"

$mGroup1 = Get-ADPrincipalGroupMembership $rUser1Info.SamAccountName | `
    ?{$_.GroupScope -eq "Global"} | %{$_.name}
$mGroup2 = Get-ADPrincipalGroupMembership $rUser2Info.SamAccountName | `
    ?{$_.GroupScope -eq "Global"} | %{$_.name}

$mGroupDiff1 = @()
$mGroupDiff2 = @()
diff $mGroup1 $mGroup2 | `
%{
    If($_.SideIndicator -eq "=>")
    {
        $mGroupDiff1 += $_.InputObject
    }
    else
    {
        $mGroupDiff2 += $_.InputObject
    }    
}

$mGroupDiffDesc = @"
【　$($rUser1Info.SamAccountName)：$($rUser1Info.DisplayName)　】
以下のユーザーグループには所属していません。
$($mGroupDiff1 -Join("`n"))

【　$($rUser2Info.SamAccountName)：$($rUser2Info.DisplayName)　】
以下のユーザーグループには所属していません。
$($mGroupDiff2 -Join("`n"))
"@

Write-Output $mGroupDiffDesc

