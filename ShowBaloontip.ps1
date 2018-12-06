Add-Type -AssemblyName "System.Web" 
Add-Type -AssemblyName "System.Windows.Forms" 
Add-Type -AssemblyName "System.Drawing" 

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null

$form = New-Object Windows.Forms.Form
$form.Text = '日程選択'
$form.Size = New-Object Drawing.Size @(273,280)
#$form.Size = New-Object Drawing.Size @(486,460)
$form.StartPosition = 'CenterScreen'

$mStartCarendar = New-Object System.Windows.Forms.MonthCalendar
$mStartCarendar.Location = New-Object System.Drawing.Point(30,40)
$mStartCarendar.ShowTodayCircle = $false
$mStartCarendar.MaxSelectionCount = 7



$mEndCarendar = New-Object System.Windows.Forms.MonthCalendar
$mEndCarendar.Location = New-Object System.Drawing.Point(200,0)
$mEndCarendar.ShowTodayCircle = $false
$mEndCarendar.MaxSelectionCount = 1

$mLabel = New-Object System.Windows.Forms.Label
$mLabel.Location = New-Object System.Drawing.Point(10,10)
$mLabel.Size = New-Object System.Drawing.Size(230,30)
$mLabel.Text = "インストール日付を指定してください。期間を指定する場合はドラッグして日付を選択してください。"

$form.Controls.Add($mStartCarendar)
#$form.Controls.Add($mEndCarendar)
$form.Controls.Add($mLabel)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(58,205)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(133,205)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$form.Topmost = $true

$menuItem1 = New-Object Windows.Forms.MenuItem "終了(&X)" 
$menuItem1.Add_Click( 
{ 
    $notifyIcon.Visible = $false 
    $notifyIcon.Dispose() 
    [Windows.Forms.Application]::Exit() 
    exit
})  

$form.ShowDialog()
[Windows.Forms.Application]::Run()

$contextMenu = New-Object Windows.Forms.ContextMenu   
[void]$contextMenu.MenuItems.Add($menuItem1)   
 
$notifyIcon = New-Object Windows.Forms.NotifyIcon 
$notifyIcon.Icon = [Drawing.Icon]::ExtractAssociatedIcon("$pshome\powershell.exe") 
$notifyIcon.Visible = $true 
$notifyIcon.ContextMenu = $contextMenu 

#$notifyIcon.Add_MouseDoubleClick( 
#{ 
#   Start-Process "notepad.exe"
#}) 

$notifyIcon.Add_BalloonTipClicked( 
{ 
    #Start-Process "notepad.exe"
    #Write-Output "AAA"

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $date = $mStartCarendar.SelectionStart
        Write-Host "Date selected: $($date.ToShortDateString())"
        $this.Text=$date.ToShortDateString() 
    }
}) 

$timer = New-Object Windows.Forms.Timer 
$log = "C:\Users\shiro\Desktop\log.txt"

$isStop = $false
$action =  
{ 
    $notifyIcon.ShowBalloonTip(9999999, "申請受理連絡", 
                    "ご依頼の申請が受理されました。クリックしてインストール日時を指定して下さい。", "Info") 
    $isEnd = $notifyIcon.Text

    If($isEnd -ne "")
    {
        Write-Host $isEnd
        $timer.Stop()
        Write-Host $timer.Enabled
        
        $notifyIcon.Visible = $false 
        $notifyIcon.Dispose() 
        [Windows.Forms.Application]::Exit()
    }
}

$timer.Interval = 10000
$timer.Add_Tick($action) 
$timer.Start() 
[Windows.Forms.Application]::Run()
