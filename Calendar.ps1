Add-Type -AssemblyName "System.Web" 
Add-Type -AssemblyName "System.Windows.Forms" 
Add-Type -AssemblyName "System.Drawing" 

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null

$form = New-Object Windows.Forms.Form
$form.Text = 'Select a Date'
#$form.Size = New-Object Drawing.Size @(243,230)
$form.Size = New-Object Drawing.Size @(486,460)
$form.StartPosition = 'CenterScreen'

$Calendar = New-Object System.Windows.Forms.MonthCalendar 
$Calendar.Location = New-Object System.Drawing.Size(10,80)
$Calendar.ShowTodayCircle = $False
$Calendar.MaxDate = (Get-Date).AddDays(1)
$Calendar.MaxSelectionCount = 1
$form.Controls.Add($Calendar) 

$form.ShowDialog()