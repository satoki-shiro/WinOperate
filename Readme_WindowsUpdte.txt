Date	Time	PID	TID	Component	Text
2005-06-01	18:30:03	992	810	Misc	= Logging initialized
2005-06-01	18:30:03	992	810	Misc	= Process:
2005-06-01	18:30:03	992	810	Misc	= Module:

(*)TID = Thread ID

Components

The following components can write to the Windowsupdate.log file:
AGENT -		Windows Update agent
AU - 		Automatic Updates is performing this task
AUCLNT - 	Interaction by AU with the logged on user
CDM - 		Device Manager
CMPRESS - 	Compression agent
COMAPI - 	Windows Update API
DRIVER - 	Device driver information
DTASTOR - 	Handles database transactions
DWNLDMGR - 	Creates and monitors download jobs
EEHNDLER - 	Expression handler used to evaluate update applicability
HANDLER - 	Manages the update installers
MISC - 		General service information
OFFLSNC - 	Detect available updates when not connected to the network
PARSER - 	Parses expression information
PT - 		Synchronizes updates information to the local datastore
REPORT - 	Collects reporting information
SERVICE - 	Startup/Shutdown of the Automatic Updates service
SETUP -		Installs new versions of the Windows Update client when available
SHUTDWN - 	Install at shutdown feature
WUREDIR - 	The Windows Update redirector files
WUWEB - 	The Windows Update ActiveX control



[ How to identify the caller ]

Identify the correct caller for the issue that you are experiencing. For example, 
if you receive an error when you are accessing the Windows Update Web site, locate the "Windowsupdate" callerID.

- Example 1

The log file distinguishes among the following three callers:
2005-06-0118:30:33 99258cAgent*************
2005-06-0118:30:33 99258cAgent** START **  Agent: Finding updates [CallerId = WindowsUpdate]
2005-06-0118:30:33 99258cAgent*********
 
- Example 2

2005-06-2213:02:111000594Agent*************
2005-06-2213:02:111000594Agent** START **  Agent: Finding updates [CallerId = MicrosoftUpdate]
2005-06-2213:02:111000594Agent********* 

- Example 3

2005-06-0211:37:18 9924e8Agent*************
2005-06-0211:37:18 9924e8Agent** START **  Agent: Finding updates [CallerId = AutomaticUpdates]
2005-06-0211:37:18 9924e8Agent*********
 
[ General configuration settings ]

The Windowsupdate.log log file records the general service settings when the Automatic Updates service starts. 
The first section records the following information:

- The client version
- The directory that is being used
- The access type
- The default proxy
- The current network state

Note The proxy is listed in the Windowsupdate.log log file only if the proxy is configured by using the Proxycfg.exe utility.
2005-06-0118:30:03 992810Service*************
2005-06-0118:30:03 992810Service** START **  Service: Service startup
2005-06-0118:30:03 992810Service*********
2005-06-0118:30:03 992810Agent  * WU client version 5.8.0.2468
2005-06-0118:30:03 992810Agent  * SusClientId = '071ffd36-f490-4d63-87a7-f7b11866b9fb'
2005-06-0118:30:03 992810Agent  * Base directory: C:\WINDOWS.0\SoftwareDistribution
2005-06-0118:30:03 992810Agent  * Access type: Named proxy
2005-06-0118:30:03 992810Agent  * Default proxy: test:80
2005-06-0118:30:03 992810Agent  * Network state: Connected
2005-06-0118:30:03 9927a0Agent***********  Agent: Initializing Windows Update Agent  ***********

 
The next section displays the Windows Server Update Services (WSUS) server that is available to the client. 
In this example, the settings are NULL because a WSUS server is not being used. 
If Software Update Services (SUS) is configured, the settings are displayed in the following location.

2005-06-0118:30:03 9927a0Agent***********  Agent: Initializing global settings cache  ***********
2005-06-0118:30:03 9927a0Agent  * WSUS server: <NULL>
2005-06-0118:30:03 9927a0Agent  * WSUS status server: <NULL>
2005-06-0118:30:03 9927a0Agent  * Target group: (Unassigned Computers)
2005-06-0118:30:03 9927a0Agent  * Windows Update access disabled: No
2005-06-0118:30:04 9927a0DnldMgrDownload manager restoring 0 downloads
2005-06-0118:30:093948918Misc===========  Logging initialized (build: 5.8.0.2469, tz: -0700)  ===========
2005-06-0118:30:093948918Misc  = Process: C:\Program Files\Internet Explorer\iexplore.exe
2005-06-0118:30:093948918Misc  = Module: C:\WINDOWS.0\system32\wuweb.dll
 
[ Locating Failures in the log file ]

If you received a specific error message on the Windows Update Web site, follow these steps:
 1. Open the Windowsupdate.log log file in Notepad.
 2. On the Edit menu, click Find, and then search for the specific error message.

Note The Web site displays the final error message. This final error message may have been caused by
 a failure that is described earlier in the Windowsupdate.log log file. Additionally, 
if you do not know which error occurred on the Windows update Web site or you want to find more information about a failure 
by Automatic Updates, search for the following key words: 
- FATAL
- WARNING

Note Not all warnings are critical errors. Start with the fatal errors and then work to the top of 
the Windowsupdate.log log file to make sure that you have identified the correct error message.

Example of a common failure

First search for the key word "FATAL":
 2005-06-0204:32:01 992158SetupFATAL: IsUpdateRequired failed with error 0x80072eef 
The error that you locate is 0x80072EEF. Scroll up in the Windowsupdate.log log file to find the following closest word:

WARNING:
 2005-06-0204:32:01 992158MiscWARNING: Send failed with hr = 80072eef.
 2005-06-0204:32:01 992158MiscWARNING: SendRequest failed with hr = 80072eef. Proxy List used: <Test:80 > Bypass List used : <(null)> Auth Schemes used : <NTLM;Negotiate (NTLM or Kerberos);>
 2005-06-0204:32:01 992158MiscWARNING: WinHttp: SendRequestUsingProxy failed for <http://update.microsoft.com/v6/windowsupdate/redir/wuredir.cab>. error 0x80072eef
 
In this example, the proxy server "Test" is not valid. The "Test" server being invalid is the cause of the error.
Basics of a Windowsupdate.log file

Service startup

 2005-06-0118:30:03 992810Service*************
 2005-06-0118:30:03 992810Service** START **  Service: Service startup
 2005-06-0118:30:03 992810Service*********
 
The Windows Update agent displays available parameters

 2005-06-0118:30:03 992810Agent  * WU client version 5.8.0.2468
 2005-06-0118:30:03 992810Agent  * SusClientId = '071ffd36-f490-4d63-87a7-f7b11866b9fb'
 2005-06-0118:30:03 992810Agent  * Base directory: C:\WINDOWS.0\SoftwareDistribution
 2005-06-0118:30:03 992810Agent  * Access type: Named proxy
 2005-06-0118:30:03 992810Agent  * Default proxy: test:80
 2005-06-0118:30:03 992810Agent  * Network state: Connected
 2005-06-0118:30:03 9927a0Agent***********  Agent: Initializing Windows Update Agent  ***********
 2005-06-0118:30:03 9927a0Agent***********  Agent: Initializing global settings cache  ***********
 2005-06-0118:30:03 9927a0Agent  * WSUS server: <NULL>
 2005-06-0118:30:03 9927a0Agent  * WSUS status server: <NULL>
 2005-06-0118:30:03 9927a0Agent  * Target group: (Unassigned Computers)

 
A user accesses the Windows Update Web site by using Microsoft Internet Explorer and the ActiveX control is loaded

 2005-06-0118:30:093948918Misc===========  Logging initialized (build: 5.8.0.2469, tz: -0700)  ===========
 2005-06-0118:30:093948918Misc  = Process: C:\Program Files\Internet Explorer\iexplore.exe
 2005-06-0118:30:093948918Misc  = Module: C:\WINDOWS.0\system32\wuweb.dll 


The Setup component checks the installed version of the Windows Update client to see if the Windows Update client must be updated

 2005-06-0118:30:093948918Setup***********  Setup: Checking whether self-update is required  ***********
 2005-06-0118:30:093948918Setup  * Inf file: C:\WINDOWS.0\SoftwareDistribution\WebSetup\wusetup.inf
 2005-06-0118:30:093948918SetupUpdate required for C:\WINDOWS.0\system32\cdm.dll: target version = 5.8.0.2468, required version = 5.8.0.2468
 2005-06-0118:30:093948918Setup  * IsUpdateRequired = No 


The client clicks the "Express" or "Custom" button to start a search

 2005-06-0118:30:323948918COMAPI-------------
 2005-06-0118:30:323948918COMAPI-- START --  COMAPI: Search [ClientId = WindowsUpdate]
 2005-06-0118:30:323948918COMAPI---------
 2005-06-0118:30:323948918COMAPI  - Online = Yes; Ignore download priority = No
 2005-06-0118:30:323948918COMAPI  - Criteria = "IsInstalled=0 and IsHidden=1"
 2005-06-0118:30:323948918COMAPI  - ServiceID = {9482F4B4-E343-43B6-B170-9A65BC822C77}

 
Note COMAPI submits the search to the agent. Therefore, the second part is:

 2005-06-0118:30:333948918COMAPI<<-- SUBMITTED -- COMAPI: Search [ClientId = WindowsUpdate]
 2005-06-0118:30:33 99258cAgent*************
 2005-06-0118:30:33 99258cAgent** START **  Agent: Finding updates [CallerId = WindowsUpdate]
 2005-06-0118:30:33 99258cAgent*********

 
Protocol talker synchronizes the list of updates with the local database on the client computer

 2005-06-0212:09:28 9924e8PT+++++++++++  PT: Synchronizing server updates  +++++++++++
 2005-06-0212:09:28 9924e8PT  + ServiceId = {9482F4B4-E343-43B6-B170-9A65BC822C77}, Server URL = https://update.microsoft.com/v6/ClientWebService/client.asmx
 2005-06-0212:09:35 9924e8PT+++++++++++  PT: Synchronizing extended update info  +++++++++++
 2005-06-0212:09:35 9924e8PT  + ServiceId = {9482F4B4-E343-43B6-B170-9A65BC822C77}, Server URL = https://update.microsoft.com/v6/ClientWebService/client.asmx
 2005-06-0212:09:36 9924e8Agent  * Found 0 updates and 10 categories in search

 
The Windows Update agent searches for available updates

 2005-06-0212:09:36 9924e8Agent*************
 2005-06-0212:09:36 9924e8Agent** START **  Agent: Finding updates [CallerId = WindowsUpdate]
 2005-06-0212:09:36 9924e8Agent*********
 2005-06-0212:09:36 9924e8Agent  * Added update {AC94DB3B-E1A8-4E92-9FD0-E86F355E6A44}.100 to search result
 2005-06-0212:09:37 9924e8Agent  * Found 6 updates and 10 categories in search 


The user is offered one update and then chooses to install the one update

 2005-06-0212:10:411660d0cCOMAPI-------------
 2005-06-0212:10:411660d0cCOMAPI-- START --  COMAPI: Install [ClientId = WindowsUpdate]
 2005-06-0212:10:411660d0cCOMAPI---------
 2005-06-0212:10:411660d0cCOMAPI  - Allow source prompts: Yes; Forced: No; Force quiet: No
 2005-06-0212:10:411660d0cCOMAPI  - Updates in request: 1
 2005-06-0212:10:411660d0cCOMAPI  - ServiceID = {9482F4B4-E343-43B6-B170-9A65BC822C77}
 2005-06-0212:10:411660d0cCOMAPI  - Updates to install = 1
 2005-06-0212:10:411660d0cCOMAPI<<-- SUBMITTED -- COMAPI: Install [ClientId = WindowsUpdate]

 
The Windows Update agent starts the installation process

 2005-06-0212:10:41 99258cAgent*************
 2005-06-0212:10:41 99258cAgent** START **  Agent: Installing updates [CallerId = WindowsUpdate]
 2005-06-0212:10:41 99258cAgent*********
 2005-06-0212:10:41 99258cAgent  * Updates to install = 1
 2005-06-0212:10:41 99258cAgent  *   Title = <NULL>
 2005-06-0212:10:41 99258cAgent  *   UpdateId = {19813D2E-0144-43CA-AEBB-71263DFD81FD}.100
 2005-06-0212:10:41 99258cAgent  *     Bundles 1 updates:
 2005-06-0212:10:41 99258cAgent  *       {08D9F87F-7EA2-4523-9F02-0931E291908E}.100

 
The Windows Update agent calls the appropriate handler to install the package by impersonating the user who is logged on

 2005-06-0212:10:46 99258cHandlerAttempting to create remote handler process as Machine\User  in session 0
 2005-06-0212:10:46 99258cDnldMgrPreparing update for install, updateId = {08D9F87F-7EA2-4523-9F02-0931E291908E}.100.
 2005-06-0212:10:47334870cHandler:::::::::::::
 2005-06-0212:10:47334870cHandler:: START ::  Handler: Command Line Install
 2005-06-0212:10:47334870cHandler:::::::::
 2005-06-0212:10:47334870cHandler  : Updates to install = 1
 2005-06-0212:11:01334870cHandler  : Command line install completed. Return code = 0x00000000, Result = Succeeded, Reboot required = false
 
Note The installation is successful and the restart is not required.
How to enable extended logging

Microsoft Product Support Services may ask you to turn on verbose logging. To turn on verbose logging, add the following registry key with two values:
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Trace
Value name: Flags
Value type: REG_DWORD
Value data: 00000007

Value name: Level
Value type: REG_DWORD
Value data: 00000004
This registry key turns on an extended tracing to the %systemroot%\Windowsupdate.log file. 
Additionally, this registry key turns on an extended tracing to any attached debuggers. 