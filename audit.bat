
rem 4672 Special privileges assigned to new logon.
rem 4673 A privileged service was called.
rem 4674 An operation was attempted on a privileged object.

rem 監査リスト表示
auditpol /get /category:*

rem 監査リストGUID表示
auditpol /list /subcategory:* /r

rem 監査リストカテゴリーGUID表示
auditpol /list /category /v

auditpol /set /subcategory:{0CCE9228-69AE-11D9-BED3-505054503030} /success:enable /failure:enable

