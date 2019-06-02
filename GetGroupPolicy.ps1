﻿$gpo=Get-ADOrganizationalUnit -Filter 'Name -like "TEST*"' | Select -ExpandProperty LinkedGroupPolicyObjects
 $gpo | %{[adsi]"LDAP://$_" | Select @{Name="zzz";Expression={$_.DisplayName[0]}}, WhenCreated, WhenChanged, gPCFileSysPath}