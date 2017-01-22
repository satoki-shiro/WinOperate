########################################################
# FileName: EventLogManager.psm1
# Update:   Jan. 22, 2017
########################################################

function CreateInsertQuery{
	param (
		[System.Array]$srcData,
		[string]$tableName
	)

    $valueQueryArray = @()
    $attrb = @(([Hashtable]$srcData[0]).Keys)
        
    foreach($row in $srcData){
        $valueArray = @()

        foreach($key in $attrb){
            if($row[$key] -is [string]){
                $strValue = [string]$row[$key]
                $valueArray += ("'" + $strValue.Replace("'","''") + "'")
            }else{
                $valueArray += $row[$key]
            }
        }
        $valueQueryArray +=  ("(" + [string]::Join(",", $valueArray)  + ")")
    }

    $execQuery = "insert into " + $tableName `
                + "(" + [string]::Join(",", $attrb)  + ") values" `
                + [string]::Join(",", $valueQueryArray)  + ";"

    return $execQuery
}

function CreateSelectQuery(){

}

function ExtractEventLogs{
	param (
        [string]$computerName,
        [string]$logName,
		[System.Array]$eventLogArray,
		[System.Array]$registerLogArray
	)

    if($eventLogArray[0].GetType().Name -ne "EventLogEntry"){
        Write-Error "ERROR: your selected log isn't the type of `"EventLogEntry`"!"
        return
    }

    for($i=0; $i-lt$eventLogArray.count; $i++){
        $rowAttr = @{}
        $rowAttr.Add("ComputerName", $computerName)
        $rowAttr.Add("LogName", $logName)

        $rowAttr.Add("EntryType", [string]$eventLogArray[$i].EntryType)
        $rowAttr.Add("InstanceId", $eventLogArray[$i].InstanceId)
        $rowAttr.Add("Message", [string]$eventLogArray[$i].Message)
        $rowAttr.Add("Category", [string]$eventLogArray[$i].Category)
        $rowAttr.Add("CategoryNumber", $eventLogArray[$i].CategoryNumber)
        $rowAttr.Add("Source", [string]$eventLogArray[$i].Source)
        $rowAttr.Add("TimeGenerated", [string]$eventLogArray[$i].TimeGenerated)
        $rowAttr.Add("UserName", [string]$eventLogArray[$i].UserName)

        $registerLogArray[$i] = $rowAttr
    }
}

function RunTask{
	param (
		[System.DateTime]$startDate,
		[System.DateTime]$endDate,
        [string]$hostName,
        [string]$logName,
        [string]$connString,
        [string]$tableName
	)    

    #STEP1: Get Server EvengLog
    $eventLogArray = Get-Eventlog -LogName $logName -After $startDate -Before $endDate
    [System.Object[]] $logArray = New-Object System.Object[] $eventLogArray.count

    #STEP2: Register Eventlogs to Database
    ExtractEventLogs -ComputerName $hostName -LogName $logName `
        -eventLogArray $eventLogArray -registerLogArray $logArray
    $registerQuery = CreateInsertQuery -srcData $logArray -tableName $tableName

    Remove-Module DataTools
    Import-Module DataTools
    Invoke-DatabaseQuery -query $registerQuery -isSQLServer -connectionString $connString
}
