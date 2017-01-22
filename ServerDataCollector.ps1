########################################################
# FileName: ServerDataCollector.ps1
# Update:   Jan. 22, 2017
########################################################

Import-Module DataTools
Import-Module EventLogManager

function RotationEventLogTable{
	param (
        [string]$connString,
        [string]$tableName,
        [DateTime]$befDate,
        [string]$tableSchema
	)    

    $befYearMonth = ($befDate).ToString("yyyyMM")
    $renameQuery = "EXEC sp_rename '" +  $tableName + "', '" + $tableName + "_" + $befYearMonth  + "';"

    #Rename Old Table
    Invoke-DatabaseQuery -query $renameQuery -isSQLServer -connectionString $connString

    #Create New Table
    Invoke-DatabaseQuery -query $tableSchema -isSQLServer -connectionString $connString
}

#STEP1: Load Configuration file.
$homeDir = (Split-Path $MyInvocation.MyCommand.Path -parent)
[String]$srvConfFile = Join-Path $homeDir "servermgt_conf.xml"
[Xml]$srvXmlDoc = Get-Content -Path $srvConfFile
[Xml.XmlElement]$srvConf = $srvXmlDoc.configuration

[String]$dbConfFile = Join-Path $homeDir "servermgt_db_conf.xml"
[Xml]$dbXmlDoc = Get-Content -Path $dbConfFile
[Xml.XmlElement]$dbConf = $dbXmlDoc.configuration


#STEP2: Run task for server logs
$logTable = $dbConf.table_list.table | Where-Object{ $_.type.contains("log") }
$logTableName = $logTable.tableName

[Datetime]$endDate =((Get-Date).AddDays(-1)).ToString("yyyy.MM.dd 23:59:59")
[Datetime]$startDate = ($endDate).AddDays(-1).AddSeconds(1)
$startDay = $startDate.Day

# - Rotate log table
if($startDay -eq 1){
    [string]$tableSchema = Get-Content(Join-Path $homeDir $logTable.schemaFile)
    RotationEventLogTable -connString $dbConf.connection.source -tableName $logTableName `
                             -befDate $startDate -tableSchema $tableSchema
}

# - Get server logs
foreach($server in $srvConf.server_list.server){
    foreach($logType in $srvConf.log_list.log){
        RunTask -startDate $startDate -endDate $endDate `
                -hostName $server.hostname -logName $logType.logname `
                -connString $dbConf.connection.source -tableName $logTableName
    }
}


#STEP3: Run task for file server resources


Remove-Module DataTools
Remove-Module EventLogManager