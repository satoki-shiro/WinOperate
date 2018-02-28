$computer = get-content C:\azam\sl.txt
$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration -computername $computer |where{$_.IPEnabled -eq “TRUE”}
  Foreach($NIC in $NICs) {

$DNSServers = “198.102.234.125",”198.102.234.126"
 $NIC.SetDNSServerSearchOrder($DNSServers)
 $NIC.SetDynamicDNSRegistration(“TRUE”)
}