Param([string]$TYPE="System", [string[]]$LEVEL=@("Warning", "Error", "Information"), [datetime]$START=(Get-Date), [datetime]$END=((Get-Date).AddHours(-1)))

# Level Description
# Level 4=information, 3=Warning, 2=Error

Get-WinEvent -FilterHashtable @{LogName=$TYPE;} | ?{($_.TimeCreated -lt $START) -and ($_.TimeCreated -ge $END)}
