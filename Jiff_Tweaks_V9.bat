@echo off
setlocal EnableExtensions EnableDelayedExpansion
title JIFF TWEAKS V9

rem ============================================================
rem  JIFF TWEAKS V9
rem  Original values are saved on first change and can be
rem  restored from the Restore menu.
rem ============================================================

rem -- admin check (fltmc works even when the Server service is disabled)
fltmc >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator rights...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
  exit /b
)

set "VER=JIFF TWEAKS V9"
set "ROOT=%SystemDrive%\JiffTweaks"
set "ORIG=%ROOT%\original"
set "LOGDIR=%ROOT%\logs"
set "TMPD=%ROOT%\tmp"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -Command"
set "LASTKB="
set "JP=5a1f6d3e-8b2c-4d7a-9e41-0c3a6b7f1d25"

for %%d in ("%ROOT%" "%ORIG%" "%ORIG%\reg" "%ORIG%\svc" "%LOGDIR%" "%TMPD%") do if not exist "%%~d" mkdir "%%~d" >nul 2>&1
for /f "usebackq delims=" %%t in (`%PS% "Get-Date -Format yyyyMMdd_HHmmss"`) do set "STAMP=%%t"
if not defined STAMP set "STAMP=session"
set "LOG=%LOGDIR%\jiff_%STAMP%.log"

call :detect
call :log "[INIT] %VER%"
call :log "[INIT] OS=!OSNAME! !DISPLAYVER! build !BUILD!"
call :log "[INIT] CPU=!CPU!"
call :log "[INIT] GPU=!GPU!"
goto MAIN

rem ============================================================
rem  MAIN MENU
rem ============================================================
:MAIN
cls
call :header
echo  1^) Apply FULL profile
echo  2^) Registry tweaks only
echo  3^) Services
echo  4^) Network
echo  5^) Power plan
echo  6^) Debloat
echo  7^) Privacy and telemetry
echo  8^) GPU  ^(NVIDIA / AMD^)
echo  9^) Expert lab
echo  B^) Branding
echo  R^) Restore originals
echo  P^) Show paths
echo  0^) Exit
echo.
set "opt="
set /p "opt=Choose option: "
if "%opt%"=="1" call :apply_full & call :press & goto MAIN
if "%opt%"=="2" call :reg_all & call :press & goto MAIN
if "%opt%"=="3" goto SVC_MENU
if "%opt%"=="4" goto NET_MENU
if "%opt%"=="5" call :power_plan & call :press & goto MAIN
if "%opt%"=="6" goto DEBLOAT_MENU
if "%opt%"=="7" call :privacy & call :press & goto MAIN
if "%opt%"=="8" goto GPU_MENU
if "%opt%"=="9" goto EXPERT_MENU
if /i "%opt%"=="B" call :branding & call :press & goto MAIN
if /i "%opt%"=="R" goto RESTORE_MENU
if /i "%opt%"=="P" call :show_paths & call :press & goto MAIN
if "%opt%"=="0" exit /b 0
goto MAIN

rem ============================================================
rem  SERVICES MENU
rem ============================================================
:SVC_MENU
cls
call :header
echo  SERVICES
echo  ------------------------------------------------------------
echo  1^) Basic     telemetry, maps, search, sysmain, time, ...
echo  2^) Standard  basic + BITS, RDP, ras, error reporting, ...
echo  3^) Advanced  everything above + Update, printing, Bluetooth,
echo               VPN, file sharing, Hyper-V, Store licensing, ...
echo  4^) Xbox services only
echo  5^) Restore services to original start types
echo  6^) Back
echo.
set "o="
set /p "o=Choose option: "
if "%o%"=="1" call :svc_basic & call :press & goto SVC_MENU
if "%o%"=="2" call :svc_standard & call :press & goto SVC_MENU
if "%o%"=="3" call :svc_advanced & call :press & goto SVC_MENU
if "%o%"=="4" call :svc_xbox & call :press & goto SVC_MENU
if "%o%"=="5" call :restore_services & call :press & goto SVC_MENU
if "%o%"=="6" goto MAIN
goto SVC_MENU

rem ============================================================
rem  NETWORK MENU
rem ============================================================
:NET_MENU
cls
call :header
echo  NETWORK
echo  ------------------------------------------------------------
echo  1^) Full network tweaks  ^(TCP globals + Nagle + NIC properties^)
echo  2^) TCP globals only
echo  3^) NIC properties + NIC power saving off
echo  4^) Network reset  ^(winsock / ip / dns flush^)
echo  5^) Back
echo.
set "o="
set /p "o=Choose option: "
if "%o%"=="1" call :net_all & call :press & goto NET_MENU
if "%o%"=="2" call :net_global & call :press & goto NET_MENU
if "%o%"=="3" call :nic_tweaks & call :press & goto NET_MENU
if "%o%"=="4" call :net_reset & call :press & goto NET_MENU
if "%o%"=="5" goto MAIN
goto NET_MENU

rem ============================================================
rem  DEBLOAT MENU
rem ============================================================
:DEBLOAT_MENU
cls
call :header
echo  DEBLOAT
echo  ------------------------------------------------------------
echo  1^) Remove consumer apps
echo  2^) Remove extended apps  ^(Teams, Copilot, Clipchamp, Bing, Xbox, ...^)
echo  3^) Uninstall OneDrive  ^(your OneDrive folder is kept^)
echo  4^) Disable bloat scheduled tasks
echo  5^) Back
echo.
set "o="
set /p "o=Choose option: "
if "%o%"=="1" call :debloat_curated & call :press & goto DEBLOAT_MENU
if "%o%"=="2" call :debloat_extended & call :press & goto DEBLOAT_MENU
if "%o%"=="3" call :debloat_onedrive & call :press & goto DEBLOAT_MENU
if "%o%"=="4" call :tasks_disable & call :press & goto DEBLOAT_MENU
if "%o%"=="5" goto MAIN
goto DEBLOAT_MENU

rem ============================================================
rem  GPU MENU
rem ============================================================
:GPU_MENU
cls
call :header
echo  GPU
echo  ------------------------------------------------------------
echo  1^) Auto  ^(apply tweaks for the detected vendor^)
echo  2^) NVIDIA  HDCP off, P-state lock, telemetry off
echo  3^) AMD  all tweaks  ^(Adrenalin + KMD + UMD + DXVA + services^)
echo  4^) Back
echo.
set "o="
set /p "o=Choose option: "
if "%o%"=="1" call :gpu_auto & call :press & goto GPU_MENU
if "%o%"=="2" call :nvidia_all & call :press & goto GPU_MENU
if "%o%"=="3" call :amd_all & call :press & goto GPU_MENU
if "%o%"=="4" goto MAIN
goto GPU_MENU

rem ============================================================
rem  EXPERT MENU
rem ============================================================
:EXPERT_MENU
cls
call :header
echo  EXPERT LAB
echo  ------------------------------------------------------------
echo  1^) Disable CPU / OS mitigations  ^(Spectre, SEHOP, CFG, VBS/HVCI^)
echo  2^) Disable Windows Defender  ^(turn Tamper Protection off first^)
echo  3^) NTFS tweaks
echo  4^) Disable memory compression + page combining
echo  5^) Delete all other power plans  ^(exported first^)
echo  6^) Back
echo.
set "o="
set /p "o=Choose option: "
if "%o%"=="1" call :mitigations_off & call :press & goto EXPERT_MENU
if "%o%"=="2" call :defender_off & call :press & goto EXPERT_MENU
if "%o%"=="3" call :ntfs_tweaks & call :press & goto EXPERT_MENU
if "%o%"=="4" call :memcomp_off & call :press & goto EXPERT_MENU
if "%o%"=="5" call :power_delete_others & call :press & goto EXPERT_MENU
if "%o%"=="6" goto MAIN
goto EXPERT_MENU

rem ============================================================
rem  RESTORE MENU
rem ============================================================
:RESTORE_MENU
cls
call :header
echo  RESTORE
echo  ------------------------------------------------------------
echo  Restores the values saved the first time each setting was changed.
echo.
echo  1^) Restore everything
echo  2^) Restore services only
echo  3^) Restore scheduled tasks only
echo  4^) Restore registry only
echo  5^) Restore power plans only
echo  6^) Forget saved originals  ^(next run saves a new baseline^)
echo  7^) Back
echo.
set "o="
set /p "o=Choose option: "
if "%o%"=="1" call :restore_all & call :press & goto RESTORE_MENU
if "%o%"=="2" call :restore_services & call :press & goto RESTORE_MENU
if "%o%"=="3" call :restore_tasks & call :press & goto RESTORE_MENU
if "%o%"=="4" call :restore_registry & call :press & goto RESTORE_MENU
if "%o%"=="5" call :restore_power & call :press & goto RESTORE_MENU
if "%o%"=="6" call :forget_originals & call :press & goto RESTORE_MENU
if "%o%"=="7" goto MAIN
goto RESTORE_MENU

rem ============================================================
rem  FULL PROFILE
rem ============================================================
:apply_full
cls
call :header
echo  FULL PROFILE
echo.
echo  Applies:
echo    - registry: latency, gaming, input, UI, priority
echo    - advanced service list + per-user service templates
echo    - scheduled task cleanup
echo    - network: TCP globals, Nagle off per interface, NIC properties
echo    - JiffOS power plan, hibernate off, USB / PnP power saving off
echo    - privacy and telemetry policies
echo    - GPU tweaks for the detected vendor
echo    - boot timer tweak ^(dynamic tick off^)
echo    - AppX debloat + OneDrive uninstall
echo.
echo  Not touched here: Windows Defender and CPU mitigations ^(Expert lab^).
echo  Removed AppX apps are not restored by the Restore menu.
echo.
choice /c YN /n /m "  Continue? [Y/N]: "
if errorlevel 2 exit /b 0
call :log "[PROFILE] FULL start"
echo.
echo [ 1/11] Restore point
%PS% "Enable-ComputerRestore -Drive '%SystemDrive%\' -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'Jiff Tweaks V9' -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue" >>"%LOG%" 2>&1
echo [ 2/11] Registry
call :reg_all
echo [ 3/11] Services
call :svc_advanced
echo.
echo [ 4/11] Scheduled tasks
call :tasks_disable
echo [ 5/11] Network
call :net_all
echo [ 6/11] Power plan
call :power_plan
echo [ 7/11] USB and PnP power saving
call :usb_power
call :pnp_power
echo [ 8/11] Privacy
call :privacy
echo [ 9/11] GPU
call :gpu_auto
echo [10/11] Boot timer
call :x "bcdedit /deletevalue useplatformclock"
call :x "bcdedit /set disabledynamictick yes"
echo [11/11] Debloat
call :debloat_curated
call :debloat_extended
call :debloat_onedrive
call :log "[PROFILE] FULL done"
echo.
echo  Done. Log: %LOG%
echo  Restart required.
echo.
choice /c YN /n /m "  Restart now? [Y/N]: "
if errorlevel 2 exit /b 0
shutdown /r /t 5 /c "Jiff Tweaks V9"
exit /b 0

rem ============================================================
rem  REGISTRY
rem ============================================================
:reg_all
call :reg_system
call :reg_gaming
call :reg_input_ui
call :reg_priority
exit /b 0

:reg_system
call :log "[REG] system / latency"
set "K_SP=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
set "K_GM=%K_SP%\Tasks\Games"
set "K_GD=HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
set "K_MM=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
set "K_KR=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
set "K_PW=HKLM\SYSTEM\CurrentControlSet\Control\Power"
rem -- MMCSS
call :reg "%K_SP%" NetworkThrottlingIndex REG_DWORD 0xffffffff
call :reg "%K_SP%" SystemResponsiveness REG_DWORD 0
call :reg "%K_SP%" AlwaysOn REG_DWORD 1
call :reg "%K_SP%" NoLazyMode REG_DWORD 1
call :reg "%K_GM%" "GPU Priority" REG_DWORD 8
call :reg "%K_GM%" Priority REG_DWORD 6
call :reg "%K_GM%" "Scheduling Category" REG_SZ High
call :reg "%K_GM%" "SFIO Priority" REG_SZ High
call :reg "%K_GM%" "Latency Sensitive" REG_SZ True
call :reg "%K_GM%" "Background Only" REG_SZ False
rem -- scheduler
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" Win32PrioritySeparation REG_DWORD 38
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" IRQ8Priority REG_DWORD 1
rem -- GPU scheduling, TDR, MPO off
call :reg "%K_GD%" HwSchMode REG_DWORD 2
call :reg "%K_GD%" TdrDelay REG_DWORD 10
call :reg "%K_GD%" TdrDdiDelay REG_DWORD 20
call :reg "%K_GD%" DpiMapIommuContiguous REG_DWORD 1
call :reg "HKLM\SOFTWARE\Microsoft\Windows\Dwm" OverlayTestMode REG_DWORD 5
call :reg "HKCU\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" DirectXUserGlobalSettings REG_SZ "VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;"
rem -- GPU power / latency tolerance
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\DXGKrnl" MonitorLatencyTolerance REG_DWORD 1
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\DXGKrnl" MonitorRefreshLatencyTolerance REG_DWORD 1
for %%v in (DefaultD3TransitionLatencyActivelyUsed DefaultD3TransitionLatencyIdleLongTime DefaultD3TransitionLatencyIdleMonitorOff DefaultD3TransitionLatencyIdleNoContext DefaultD3TransitionLatencyIdleShortTime DefaultD3TransitionLatencyIdleVeryLongTime DefaultLatencyToleranceIdle0 DefaultLatencyToleranceIdle0MonitorOff DefaultLatencyToleranceIdle1 DefaultLatencyToleranceIdle1MonitorOff DefaultLatencyToleranceMemory DefaultLatencyToleranceNoContext DefaultLatencyToleranceNoContextMonitorOff DefaultLatencyToleranceOther DefaultLatencyToleranceTimerPeriod DefaultMemoryRefreshLatencyToleranceActivelyUsed DefaultMemoryRefreshLatencyToleranceMonitorOff DefaultMemoryRefreshLatencyToleranceNoContext Latency MonitorLatencyTolerance MonitorRefreshLatencyTolerance TransitionLatency) do call :reg "%K_GD%\Power" %%v REG_DWORD 1
rem -- power
call :reg "%K_PW%\PowerThrottling" PowerThrottlingOff REG_DWORD 1
call :reg "%K_PW%" HiberbootEnabled REG_DWORD 0
call :reg "%K_PW%" CsEnabled REG_DWORD 0
call :reg "%K_PW%" EnergyEstimationEnabled REG_DWORD 0
call :reg "%K_PW%" EventProcessorEnabled REG_DWORD 0
rem -- memory
call :reg "%K_MM%" DisablePagingExecutive REG_DWORD 1
call :reg "%K_MM%" LargeSystemCache REG_DWORD 0
call :reg "%K_MM%" DisablePagingCombining REG_DWORD 1
rem -- timers
call :reg "%K_KR%" GlobalTimerResolutionRequests REG_DWORD 1
call :reg "%K_KR%" DistributeTimers REG_DWORD 1
rem -- filesystem
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" NtfsDisableLastAccessUpdate REG_DWORD 1
rem -- USB selective suspend
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\USB" DisableSelectiveSuspend REG_DWORD 1
rem -- shutdown / hang timeouts
call :reg "HKLM\SYSTEM\CurrentControlSet\Control" WaitToKillServiceTimeout REG_SZ 1000
call :reg "HKCU\Control Panel\Desktop" WaitToKillAppTimeout REG_SZ 1000
call :reg "HKCU\Control Panel\Desktop" HungAppTimeout REG_SZ 1000
call :reg "HKCU\Control Panel\Desktop" AutoEndTasks REG_SZ 1
rem -- startup delay
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" StartupDelayInMSec REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" WaitforIdleState REG_DWORD 0
rem -- background apps / activity feed
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" GlobalUserDisabled REG_DWORD 1
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" BackgroundAppGlobalToggle REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" LetAppsRunInBackground REG_DWORD 2
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" EnableActivityFeed REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" PublishUserActivities REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" UploadUserActivities REG_DWORD 0
call :log "[OK] system registry done"
exit /b 0

:reg_gaming
call :log "[REG] gaming"
set "K_GC=HKCU\System\GameConfigStore"
call :reg "%K_GC%" GameDVR_Enabled REG_DWORD 0
call :reg "%K_GC%" GameDVR_FSEBehaviorMode REG_DWORD 2
call :reg "%K_GC%" GameDVR_HonorUserFSEBehaviorMode REG_DWORD 1
call :reg "%K_GC%" GameDVR_DXGIHonorFSEWindowsCompatible REG_DWORD 1
call :reg "%K_GC%" GameDVR_EFSEFeatureFlags REG_DWORD 0
call :reg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" AppCaptureEnabled REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" AllowGameDVR REG_DWORD 0
call :reg "HKCU\SOFTWARE\Microsoft\GameBar" AllowAutoGameMode REG_DWORD 1
call :reg "HKCU\SOFTWARE\Microsoft\GameBar" AutoGameModeEnabled REG_DWORD 1
call :reg "HKCU\SOFTWARE\Microsoft\GameBar" ShowStartupPanel REG_DWORD 0
call :reg "HKCU\SOFTWARE\Microsoft\GameBar" UseNexusForGameBarEnabled REG_DWORD 0
call :log "[OK] gaming registry done"
exit /b 0

:reg_input_ui
call :log "[REG] input / UI"
set "K_MS=HKCU\Control Panel\Mouse"
call :reg "%K_MS%" MouseSpeed REG_SZ 0
call :reg "%K_MS%" MouseThreshold1 REG_SZ 0
call :reg "%K_MS%" MouseThreshold2 REG_SZ 0
call :reg "%K_MS%" MouseSensitivity REG_SZ 10
call :reg "%K_MS%" MouseHoverTime REG_SZ 0
call :reg "HKU\.DEFAULT\Control Panel\Mouse" MouseSpeed REG_SZ 0
call :reg "HKU\.DEFAULT\Control Panel\Mouse" MouseThreshold1 REG_SZ 0
call :reg "HKU\.DEFAULT\Control Panel\Mouse" MouseThreshold2 REG_SZ 0
call :reg "HKCU\Control Panel\Desktop" MenuShowDelay REG_SZ 0
call :reg "HKCU\Control Panel\Desktop\WindowMetrics" MinAnimate REG_SZ 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" TaskbarAnimations REG_DWORD 0
call :log "[OK] input / UI registry done"
exit /b 0

:reg_priority
call :log "[REG] priority"
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System" PassiveIntRealTimeWorkerPriority REG_DWORD 18
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\KernelVelocity" DisableFGBoostDecay REG_DWORD 1
set "K_IF=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
for %%e in (SearchIndexer.exe TrustedInstaller.exe wuauclt.exe) do (
  call :reg "%K_IF%\%%e\PerfOptions" CpuPriorityClass REG_DWORD 1
  call :reg "%K_IF%\%%e\PerfOptions" IoPriority REG_DWORD 0
)
call :log "[OK] priority registry done"
exit /b 0

rem ============================================================
rem  SERVICES
rem ============================================================
:svc_basic
call :log "[SVC] basic"
for %%s in (DoSvc diagsvc DPS dmwappushservice MapsBroker lfsvc CscService SEMgrSvc PhoneSvc RemoteRegistry RetailDemo SysMain WalletService WSearch W32Time) do call :svc %%s
for %%s in (MessagingService WpnUserService) do call :svc %%s
echo.
call :log "[OK] basic services done"
exit /b 0

:svc_standard
call :log "[SVC] standard"
for %%s in (AJRouter tzautoupdate BITS DiagTrack CDPSvc DusmSvc DoSvc diagsvc DPS WdiServiceHost WdiSystemHost dmwappushservice DisplayEnhancementService MapsBroker fhsvc lfsvc HomeGroupListener HomeGroupProvider SmsRouter CscService SEMgrSvc pla PhoneSvc WpcMonSvc) do call :svc %%s
for %%s in (RasAuto RasMan SessionEnv TermService RpcLocator RemoteRegistry RetailDemo SysMain WalletService WerSvc WSearch W32Time) do call :svc %%s
for %%s in (BcastDVRUserService MessagingService WpnUserService) do call :svc %%s
echo.
call :log "[OK] standard services done"
exit /b 0

:svc_advanced
call :log "[SVC] advanced"
rem -- telemetry / diagnostics / sync
for %%s in (AJRouter DiagTrack diagsvc DPS WdiServiceHost WdiSystemHost diagnosticshub.standardcollector.service dmwappushservice IEEtwCollectorService PcaSvc WerSvc wmiApSrv pla DusmSvc CDPSvc lfsvc MapsBroker tzautoupdate DisplayEnhancementService) do call :svc %%s
rem -- update / delivery / store
for %%s in (wuauserv WaaSMedicSvc UsoSvc BITS DoSvc InstallService ClipSVC LicenseManager AppXSvc WpnService wlidsvc) do call :svc %%s
rem -- search / indexing / prefetch / misc shell
for %%s in (WSearch SysMain W32Time FontCache FontCache3.0.0.0 tiledatamodelsvc TabletInputService ShellHWDetection StorSvc TieringEngineService defragsvc TrkWks fhsvc) do call :svc %%s
rem -- network / sharing / remote
for %%s in (AppMgmt ALG PeerDistSvc fdPHost FDResPub lltdsvc p2psvc p2pimsvc PNRPsvc PNRPAutoReg iphlpsvc IpxlatCfgSvc PolicyAgent SharedAccess lmhosts LanmanServer LanmanWorkstation WebClient QWAVE wcncsvc WFDSConMgrSvc icssvc WMPNetworkSvc spectrum) do call :svc %%s
for %%s in (RasAuto RasMan RemoteAccess SessionEnv TermService UmRdpService RpcLocator RemoteRegistry WinRM Wecsvc SNMPTRAP MSiSCSI irmon) do call :svc %%s
rem -- virtualization
for %%s in (HvHost hns vmickvpexchange vmicguestinterface vmicshutdown vmicheartbeat vmicvmsession vmicrdv vmictimesync vmicvss AppVClient UevAgentService) do call :svc %%s
rem -- bluetooth / sensors / devices / printing / cards
for %%s in (BTAGService bthserv BthHFSrv PhoneSvc WPDBusEnum Spooler PrintNotify SCardSvr ScDeviceEnum SCPolicySvc StiSvc WbioSrvc FrameServer SensorDataService SensrSvc SensorService NaturalAuthentication RmSvc TapiSrv SmsRouter SDRSVC wisvc) do call :svc %%s
rem -- security / enterprise / misc
for %%s in (BDESVC wbengine VaultSvc CertPropSvc EFS EntAppSvc AssignedAccessManagerSvc MSDTC smphost seclogon shpamsvc SgrmBroker WpcMonSvc WEPHOSTSVC SharedRealitySvc perceptionsimulation CscService SEMgrSvc RetailDemo WalletService) do call :svc %%s
rem -- xbox
call :svc_xbox_list
rem -- legacy homegroup
for %%s in (HomeGroupListener HomeGroupProvider) do call :svc %%s
rem -- per-user service templates
for %%s in (BluetoothUserService CDPUserSvc CaptureService ConsentUxUserSvc PimIndexMaintenanceSvc DevicePickerUserSvc DevicesFlowUserSvc BcastDVRUserService MessagingService PrintWorkflowUserSvc OneSyncSvc UserDataSvc UnistoreSvc WpnUserService) do call :svc %%s
echo.
call :log "[OK] advanced services done"
echo  Kept enabled on purpose: SamSs, Themes, TokenBroker, Defender and Security Center ^(Expert lab^).
exit /b 0

:svc_xbox
call :log "[SVC] xbox"
call :svc_xbox_list
echo.
exit /b 0

:svc_xbox_list
for %%s in (XboxGipSvc xbgm XblAuthManager XblGameSave XboxNetApiSvc) do call :svc %%s
exit /b 0

:svc
rem  call :svc NAME   - disable service, record original start type once
set "SN=%~1"
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SN%" /v Start >nul 2>&1
if errorlevel 1 (call :log "[SKIP-SVC] %SN% not present" & exit /b 0)
if not exist "%ORIG%\svc\%SN%.txt" (
  set "ST="
  for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%SN%" /v Start ^| findstr /c:"REG_DWORD"') do set "ST=%%a"
  if defined ST >"%ORIG%\svc\%SN%.txt" echo !ST!
)
sc stop "%SN%" >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\%SN%" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
if errorlevel 1 (
  sc config "%SN%" start= disabled >nul 2>&1
  if errorlevel 1 (call :log "[FAIL-SVC] %SN% protected") else (call :log "[OK-SVC] %SN%")
) else (
  call :log "[OK-SVC] %SN%"
)
<nul set /p "=."
exit /b 0

rem ============================================================
rem  SCHEDULED TASKS
rem ============================================================
:tasks_disable
call :log "[TASKS] disable"
set "TL=%TMPD%\tasks.lst"
if exist "%TL%" del /f /q "%TL%" >nul 2>&1
for %%t in ("\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "\Microsoft\Windows\Application Experience\StartupAppTask" "\Microsoft\Windows\Application Experience\PcaPatchDbTask" "\Microsoft\Windows\Application Experience\MareBackup" "\Microsoft\Windows\Autochk\Proxy" "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "\Microsoft\Windows\DiskFootprint\Diagnostics" "\Microsoft\Windows\Feedback\Siuf\DmClient" "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "\Microsoft\Windows\Windows Error Reporting\QueueReporting" "\Microsoft\Windows\Maps\MapsToastTask" "\Microsoft\Windows\Maps\MapsUpdateTask" "\Microsoft\Windows\Shell\FamilySafetyMonitor" "\Microsoft\Windows\Shell\FamilySafetyRefreshTask" "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" "\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures" "\Microsoft\Windows\Flighting\OneSettings\RefreshCache" "\Microsoft\Windows\Device Information\Device" "\Microsoft\Windows\NetTrace\GatherNetworkInfo" "\Microsoft\Windows\PI\Sqm-Tasks" "\Microsoft\Windows\Location\Notifications" "\Microsoft\Windows\Location\WindowsActionDialog" "\Microsoft\Windows\WDI\ResolutionHost" "\Microsoft\XblGameSave\XblGameSaveTask" "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" "\Microsoft\Windows\Work Folders\Work Folders Logon Synchronization" "\Microsoft\Windows\Work Folders\Work Folders Maintenance Work" "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary" "\Microsoft\Windows\SettingSync\BackgroundUploadTask" "\Microsoft\Windows\SettingSync\NetworkStateChangeTask") do >>"%TL%" echo %%~t
%PS% "$o='%ORIG%\tasks.txt'; $n=0; Get-Content '%TL%' | ForEach-Object { $p=Split-Path $_ -Parent; $l=Split-Path $_ -Leaf; $t=Get-ScheduledTask -TaskPath ($p+'\') -TaskName $l -ErrorAction SilentlyContinue; if($t -and $t.State -ne 'Disabled'){ Disable-ScheduledTask -InputObject $t -ErrorAction SilentlyContinue | Out-Null; Add-Content $o $_; $n++ } }; Write-Output ('tasks disabled: '+$n)" >>"%LOG%" 2>&1
call :log "[OK] tasks done"
exit /b 0

:restore_tasks
call :log "[RESTORE] tasks"
if not exist "%ORIG%\tasks.txt" (echo  No task changes recorded. & exit /b 0)
%PS% "Get-Content '%ORIG%\tasks.txt' | ForEach-Object { $p=Split-Path $_ -Parent; $l=Split-Path $_ -Leaf; $t=Get-ScheduledTask -TaskPath ($p+'\') -TaskName $l -ErrorAction SilentlyContinue; if($t){ Enable-ScheduledTask -InputObject $t -ErrorAction SilentlyContinue | Out-Null } }" >>"%LOG%" 2>&1
echo  Tasks restored.
exit /b 0

rem ============================================================
rem  NETWORK
rem ============================================================
:net_all
call :net_global
call :net_interfaces
call :nic_tweaks
exit /b 0

:net_global
call :log "[NET] TCP globals"
call :x "netsh int tcp set global autotuninglevel=normal"
call :x "netsh int tcp set global rss=enabled"
call :x "netsh int tcp set global rsc=disabled"
call :x "netsh int tcp set global ecncapability=disabled"
call :x "netsh int tcp set global timestamps=disabled"
call :x "netsh int tcp set global nonsackrttresiliency=disabled"
call :x "netsh int tcp set global initialrto=2000"
call :x "netsh int tcp set global maxsynretransmissions=2"
call :x "netsh int tcp set global dca=enabled"
call :x "netsh int tcp set heuristics disabled"
call :x "netsh int udp set global uro=disabled"
call :x "netsh int ip set global neighborcachelimit=4096"
call :x "netsh int teredo set state disabled"
call :x "netsh int 6to4 set state disabled"
call :x "netsh int isatap set state disabled"
set "K_TP=HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
call :reg "%K_TP%" TcpTimedWaitDelay REG_DWORD 30
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" LocalPriority REG_DWORD 4
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" HostsPriority REG_DWORD 5
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" DnsPriority REG_DWORD 6
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" NetbtPriority REG_DWORD 7
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" NonBestEffortLimit REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" DODownloadMode REG_DWORD 0
call :log "[OK] TCP globals done"
exit /b 0

:net_interfaces
call :log "[NET] per-interface Nagle off"
for /f "delims=" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul') do (
  call :reg "%%k" TcpAckFrequency REG_DWORD 1
  call :reg "%%k" TCPNoDelay REG_DWORD 1
  call :reg "%%k" TcpDelAckTicks REG_DWORD 0
)
call :log "[OK] interfaces done"
exit /b 0

:nic_tweaks
call :log "[NIC] adapter properties"
for /f "delims=" %%r in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /f "PCI\VEN" /d 2^>nul ^| findstr /b /c:"HKEY"') do (
  call :key4 "%%r" && (set "NICK=%%r" & call :nic_one)
)
call :log "[OK] NIC done"
exit /b 0

:nic_one
rem  allow computer to turn off device / wake: both unchecked
call :reg "%NICK%" PnPCapabilities REG_DWORD 24
rem  names starting with @ stand for a leading * (wildcards would be expanded by FOR)
for %%p in (@EEE EEE AdvancedEEE EEELinkAdvertisement EnableGreenEthernet GigaLite PowerSavingMode ULPMode AutoDisableGigabit EnablePME @FlowControl @InterruptModeration ITR @LsoV1IPv4 @LsoV2IPv4 @LsoV2IPv6 @PMARPOffload @PMNSOffload @WakeOnMagicPacket @WakeOnPattern @ModernStandbyWoLMagicPacket S5WakeOnLan WakeOnLink) do (
  set "PN=%%p"
  set "PN=!PN:@=*!"
  reg query "!NICK!" /v "!PN!" >nul 2>&1
  if not errorlevel 1 call :reg "!NICK!" "!PN!" REG_SZ 0
)
exit /b 0

:net_reset
call :x "netsh winsock reset"
call :x "netsh int ip reset"
call :x "ipconfig /flushdns"
echo  Network stack reset. Restart required.
exit /b 0

rem ============================================================
rem  POWER
rem ============================================================
:power_save
if exist "%ORIG%\power_saved.flag" exit /b 0
%PS% "$a=(powercfg /getactivescheme | Select-String -Pattern '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}').Matches[0].Value; Set-Content '%ORIG%\power_active.txt' $a" >>"%LOG%" 2>&1
%PS% "powercfg /list | Select-String -Pattern '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}' | ForEach-Object { $_.Matches[0].Value }" >"%TMPD%\plans.txt" 2>nul
for /f %%g in (%TMPD%\plans.txt) do powercfg /export "%ORIG%\plan_%%g.pow" %%g >nul 2>&1
>"%ORIG%\power_saved.flag" echo 1
call :log "[POWER] original plans exported"
exit /b 0

:power_plan
call :log "[POWER] JiffOS plan"
call :power_save
powercfg /list | findstr /i "%JP%" >nul 2>&1
if not errorlevel 1 goto power_activate
set "FROMPOW=0"
if exist "%~dp0JiffOSUltimate.pow" (
  powercfg /import "%~dp0JiffOSUltimate.pow" %JP% >nul 2>&1
  if not errorlevel 1 set "FROMPOW=1"
)
powercfg /list | findstr /i "%JP%" >nul 2>&1
if not errorlevel 1 goto power_tune
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 %JP% >nul 2>&1
if not errorlevel 1 goto power_name
powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c %JP% >nul 2>&1
if not errorlevel 1 goto power_name
powercfg /duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e %JP% >nul 2>&1
if errorlevel 1 (
  call :log "[FAIL] could not create power plan"
  echo  Power plan could not be created.
  exit /b 0
)
:power_name
powercfg /changename %JP% "JiffOS Ultimate" "Maximum performance, no power saving" >nul 2>&1
:power_tune
if "%FROMPOW%"=="1" goto power_activate
rem  subgroup / setting GUIDs: processor min, max, boost mode, EPP, core parking min/max, cooling,
rem  standby idle, hibernate idle, hybrid sleep, disk idle, PCIe ASPM, USB selective suspend, wireless power saving
for %%a in (
  "54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100"
  "54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100"
  "54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2"
  "54533251-82be-4824-96c1-47b60b740d00 36687f9e-e3a5-4dbf-b1dc-15eb381c6863 0"
  "54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100"
  "54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 100"
  "54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1"
  "238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0"
  "238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0"
  "238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0"
  "0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0"
  "501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0"
  "2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0"
  "19cbb8fa-5279-450e-9fac-8a3d34e1e29d 12bbebe6-58d6-4636-95bb-3217ef867c1a 0"
) do powercfg /setacvalueindex %JP% %%~a >nul 2>&1
:power_activate
powercfg /setactive %JP% >nul 2>&1
if errorlevel 1 (call :log "[FAIL] setactive") else (call :log "[OK] JiffOS plan active")
call :x "powercfg /hibernate off"
echo  JiffOS power plan active ^(AC^). Hibernate and Fast Startup off.
exit /b 0

:power_delete_others
call :log "[POWER] delete other plans"
call :power_save
%PS% "powercfg /list | Select-String -Pattern '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}' | ForEach-Object { $_.Matches[0].Value }" >"%TMPD%\plans.txt" 2>nul
powercfg /setactive %JP% >nul 2>&1
if errorlevel 1 (
  echo  JiffOS plan is not active. Run the Power plan option first.
  exit /b 0
)
for /f %%g in (%TMPD%\plans.txt) do call :power_del1 %%g
echo  Other plans deleted. Originals are exported in %ORIG%
exit /b 0

:power_del1
if /i "%~1"=="%JP%" exit /b 0
powercfg /delete %~1 >nul 2>&1
call :log "[POWER] deleted %~1"
exit /b 0

:restore_power
call :log "[RESTORE] power"
if not exist "%ORIG%\power_saved.flag" (echo  No power plan backup found. & exit /b 0)
for /f "delims=" %%f in ('dir /b "%ORIG%\plan_*.pow" 2^>nul') do (
  set "PN=%%~nf"
  set "PG=!PN:plan_=!"
  powercfg /list | findstr /i "!PG!" >nul 2>&1
  if errorlevel 1 powercfg /import "%ORIG%\%%f" !PG! >nul 2>&1
)
set "AG="
if exist "%ORIG%\power_active.txt" set /p "AG=" <"%ORIG%\power_active.txt"
if defined AG powercfg /setactive !AG! >nul 2>&1
if errorlevel 1 powercfg /restoredefaultschemes >nul 2>&1
powercfg /delete %JP% >nul 2>&1
echo  Power plans restored.
exit /b 0

:usb_power
call :log "[USB] idle power saving off"
%PS% "$names='EnhancedPowerManagementEnabled','AllowIdleIrpInD3','EnableSelectiveSuspend','DeviceSelectiveSuspended','SelectiveSuspendEnabled','SelectiveSuspendOn','WaitWakeEnabled','D3ColdSupported','WdfDirectedPowerTransitionEnable','EnableIdlePowerManagement','IdleInWorkingState'; $csv='%ORIG%\usb_power.csv'; $seen=@{}; if(Test-Path $csv){ Get-Content $csv | ForEach-Object { $seen[$_.Substring(0,$_.LastIndexOf('|'))]=1 } }; $n=0; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum' -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $k=$_; $vn=$k.GetValueNames(); foreach($nm in $names){ if($vn -contains $nm){ $v=$k.GetValue($nm); if(($v -is [int]) -and ($v -ne 0)){ $id=$k.Name+'|'+$nm; if(-not $seen.ContainsKey($id)){ Add-Content $csv ($id+'|'+$v); $seen[$id]=1 }; try{ Set-ItemProperty -LiteralPath $k.PSPath -Name $nm -Value 0 -ErrorAction Stop; $n++ }catch{} } } } }; Write-Output ('USB flags cleared: '+$n)" >>"%LOG%" 2>&1
call :log "[OK] USB done"
exit /b 0

:pnp_power
call :log "[PNP] device power saving off"
%PS% "$csv='%ORIG%\pnp_power.csv'; $n=0; Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue | ForEach-Object { if($_.Enable){ if(-not (Test-Path $csv) -or -not (Select-String -Path $csv -SimpleMatch $_.InstanceName -Quiet)){ Add-Content $csv $_.InstanceName }; $_.Enable=$false; $_.psbase.Put() | Out-Null; $n++ } }; Write-Output ('PnP devices updated: '+$n)" >>"%LOG%" 2>&1
call :log "[OK] PnP done"
exit /b 0

:restore_devpower
if exist "%ORIG%\usb_power.csv" %PS% "Get-Content '%ORIG%\usb_power.csv' | ForEach-Object { $p=$_.Split('|'); Set-ItemProperty -LiteralPath ('Registry::'+$p[0]) -Name $p[1] -Value ([int]$p[2]) -ErrorAction SilentlyContinue }" >>"%LOG%" 2>&1
if exist "%ORIG%\pnp_power.csv" %PS% "Get-Content '%ORIG%\pnp_power.csv' | ForEach-Object { $i=$_; Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.InstanceName -eq $i } | ForEach-Object { $_.Enable=$true; $_.psbase.Put() | Out-Null } }" >>"%LOG%" 2>&1
exit /b 0

rem ============================================================
rem  PRIVACY
rem ============================================================
:privacy
call :log "[PRIVACY] start"
set "K_DC=HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
call :reg "%K_DC%" AllowTelemetry REG_DWORD 0
call :reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" AllowTelemetry REG_DWORD 0
call :reg "%K_DC%" LimitDiagnosticLogCollection REG_DWORD 1
call :reg "%K_DC%" DisableOneSettingsDownloads REG_DWORD 1
call :reg "%K_DC%" DoNotShowFeedbackNotifications REG_DWORD 1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" AllowCortana REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" CortanaConsent REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" HistoryViewEnabled REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" DeviceHistoryEnabled REG_DWORD 0
call :reg "HKCU\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions REG_DWORD 1
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" DisabledByGroupPolicy REG_DWORD 1
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" TailoredExperiencesWithDiagnosticDataEnabled REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" DisableLocation REG_DWORD 1
set "K_WE=HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
call :reg "%K_WE%" Disabled REG_DWORD 1
call :reg "%K_WE%" DoReport REG_DWORD 0
call :reg "%K_WE%" LoggingDisabled REG_DWORD 1
call :reg "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" Disabled REG_DWORD 1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" AllowWindowsInkWorkspace REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" DisableWindowsConsumerFeatures REG_DWORD 1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" DisableSoftLanding REG_DWORD 1
set "K_CD=HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%v in (SystemPaneSuggestionsEnabled SilentInstalledAppsEnabled PreInstalledAppsEnabled OemPreInstalledAppsEnabled ContentDeliveryAllowed SubscribedContentEnabled FeatureManagementEnabled SoftLandingEnabled RotatingLockScreenOverlayEnabled SubscribedContent-310093Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled) do call :reg "%K_CD%" %%v REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" ShowFrequent REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" ShowRecent REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" NoRecentDocsHistory REG_DWORD 1
call :tasks_disable
call :log "[OK] privacy done"
exit /b 0

rem ============================================================
rem  DEBLOAT
rem ============================================================
:appx_run
rem  removes every package name listed in %APPLIST% for all users and from the provisioned image
%PS% "$prov=Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; Get-Content '%APPLIST%' | ForEach-Object { $n=$_.Trim(); if($n){ Get-AppxPackage -AllUsers -Name $n -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; $prov | Where-Object { $_.DisplayName -eq $n } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null } } }" >>"%LOG%" 2>&1
exit /b 0

:debloat_curated
call :log "[DEBLOAT] curated AppX"
set "APPLIST=%TMPD%\apps_curated.lst"
if exist "%APPLIST%" del /f /q "%APPLIST%" >nul 2>&1
for %%a in (Microsoft.BingWeather Microsoft.GetHelp Microsoft.Getstarted Microsoft.MicrosoftOfficeHub Microsoft.MicrosoftSolitaireCollection Microsoft.MixedReality.Portal Microsoft.People Microsoft.SkypeApp Microsoft.Wallet Microsoft.WindowsAlarms Microsoft.WindowsFeedbackHub Microsoft.WindowsMaps Microsoft.WindowsSoundRecorder Microsoft.YourPhone Microsoft.ZuneMusic Microsoft.ZuneVideo Microsoft.Xbox.TCUI Microsoft.XboxApp Microsoft.XboxGameOverlay Microsoft.XboxGamingOverlay Microsoft.XboxIdentityProvider Microsoft.XboxSpeechToTextOverlay) do >>"%APPLIST%" echo %%a
call :appx_run
call :log "[OK] curated debloat done"
exit /b 0

:debloat_extended
call :log "[DEBLOAT] extended AppX"
for %%p in (OneDrive.exe Teams.exe ms-teams.exe Cortana.exe widgets.exe) do taskkill /f /im %%p >nul 2>&1
set "APPLIST=%TMPD%\apps_extended.lst"
if exist "%APPLIST%" del /f /q "%APPLIST%" >nul 2>&1
for %%a in (Microsoft.549981C3F5F10 Microsoft.BingNews Microsoft.BingSearch Microsoft.BingFinance Microsoft.BingSports Microsoft.BingTranslator Microsoft.GamingApp Microsoft.MicrosoftJournal Microsoft.MicrosoftMahjong Microsoft.MicrosoftCasualGames Microsoft.Office.OneNote Microsoft.OutlookForWindows Microsoft.Todos MicrosoftCorporationII.MicrosoftFamily microsoft.windowscommunicationsapps Microsoft.PowerAutomateDesktop MicrosoftCorporationII.WindowsSubsystemForAndroid Clipchamp.Clipchamp Microsoft.Teams MicrosoftTeams MSTeams Microsoft.Copilot Microsoft.Windows.DevHome MicrosoftWindows.Client.WebExperience) do >>"%APPLIST%" echo %%a
call :appx_run
call :log "[OK] extended debloat done"
exit /b 0

:debloat_onedrive
call :log "[DEBLOAT] OneDrive"
taskkill /f /im OneDrive.exe >nul 2>&1
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
if exist "%SystemRoot%\System32\OneDriveSetup.exe" "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
rem  rd without /s only removes the folder when it is empty, so synced files are never deleted
rd "%UserProfile%\OneDrive" >nul 2>&1
rd /s /q "%LocalAppData%\Microsoft\OneDrive" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft OneDrive" >nul 2>&1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" DisableFileSyncNGSC REG_DWORD 1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
call :log "[OK] OneDrive done"
exit /b 0

rem ============================================================
rem  GPU
rem ============================================================
:gpu_auto
if "!HAS_NV!"=="1" call :nvidia_all
if "!HAS_AMD!"=="1" call :amd_all
if "!HAS_NV!!HAS_AMD!"=="00" (call :log "[GPU] no NVIDIA / AMD adapter detected" & echo  No NVIDIA or AMD adapter detected.)
exit /b 0

:gpu_keys
rem  call :gpu_keys VEN_xxxx LABEL   - runs LABEL once per display class key of that vendor
set "GCLS=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
for /f "delims=" %%k in ('reg query "%GCLS%" /s /f "%~1" /d 2^>nul ^| findstr /b /c:"HKEY"') do (
  call :key4 "%%k" && call %~2 "%%k"
)
exit /b 0

:key4
rem  errorlevel 0 when the last component of a registry path is exactly four digits (class instance key)
set "K4=%~nx1"
set "K4N=1"
for /f "delims=0123456789" %%z in ("!K4!") do set "K4N=0"
if "!K4N!"=="0" exit /b 1
if "!K4:~3,1!"=="" exit /b 1
if not "!K4:~4,1!"=="" exit /b 1
exit /b 0

:nvidia_all
call :log "[NVIDIA] tweaks"
call :gpu_keys VEN_10DE :nv_apply
call :reg "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" OptInOrOutPreference REG_DWORD 0
call :reg "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" SendTelemetryData REG_DWORD 0
call :svc NvTelemetryContainer
%PS% "Get-ScheduledTask -TaskName 'NvTm*','NvDriverUpdateCheck*','NvProfileUpdater*' -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null" >>"%LOG%" 2>&1
call :log "[OK] NVIDIA done"
echo  NVIDIA tweaks applied. Restart required.
exit /b 0

:nv_apply
call :reg "%~1" RMHdcpKeyglobZero REG_DWORD 1
call :reg "%~1" DisableDynamicPstate REG_DWORD 1
exit /b 0

:amd_all
call :log "[AMD] tweaks"
call :amd_software
call :amd_dvr
call :gpu_keys VEN_1002 :amd_apply
call :amd_services
call :log "[OK] AMD done"
echo  AMD tweaks applied. Restart required.
exit /b 0

:amd_software
set "K_CN=HKCU\Software\AMD\CN"
call :reg "%K_CN%" AutoUpdateTriggered REG_DWORD 0
call :reg "%K_CN%" PowerSaverAutoEnable_CUR REG_DWORD 0
call :reg "%K_CN%" BuildType REG_DWORD 0
call :reg "%K_CN%" WizardProfile REG_SZ PROFILE_CUSTOM
call :reg "%K_CN%" UserTypeWizardShown REG_DWORD 1
call :reg "%K_CN%" AutoUpdate REG_DWORD 0
call :reg "%K_CN%" RSXBrowserUnavailable REG_SZ true
call :reg "%K_CN%" SystemTray REG_SZ false
call :reg "%K_CN%" AllowWebContent REG_SZ false
call :reg "%K_CN%" CN_Hide_Toast_Notification REG_SZ true
call :reg "%K_CN%" AnimationEffect REG_SZ false
call :reg "%K_CN%\OverlayNotification" AlreadyNotified REG_DWORD 1
call :reg "%K_CN%\VirtualSuperResolution" AlreadyNotified REG_DWORD 1
call :reg "HKLM\Software\AMD\Install" AUEP REG_DWORD 1
call :reg "HKLM\Software\AUEP" RSX_AUEPStatus REG_DWORD 2
call :reg "HKCU\Software\ATI\ACE\Settings\ADL\AppProfiles" AplReloadCounter REG_DWORD 0
exit /b 0

:amd_dvr
set "K_DV=HKCU\Software\AMD\DVR"
call :reg "%K_DV%" PerformanceMonitorOpacityWA REG_DWORD 0
call :reg "%K_DV%" DvrEnabled REG_DWORD 0
call :reg "%K_DV%" ActiveSceneId REG_SZ 0
call :reg "%K_DV%" PrevInstantReplayEnable REG_DWORD 0
call :reg "%K_DV%" PrevInGameReplayEnabled REG_DWORD 0
call :reg "%K_DV%" PrevInstantGifEnabled REG_DWORD 0
call :reg "%K_DV%" RemoteServerStatus REG_DWORD 0
call :reg "%K_DV%" ShowRSOverlay REG_SZ false
exit /b 0

:amd_services
call :reg "HKLM\System\CurrentControlSet\Services\amdwddmg" ChillEnabled REG_DWORD 0
for %%s in ("AMD Crash Defender Service" "AMD External Events Utility" amdfendr amdfendrmgr amdlog) do call :svc "%%~s"
exit /b 0

:amd_apply
set "AK=%~1"
rem -- KMD
call :reg "%AK%" NotifySubscription REG_BINARY 3000
call :reg "%AK%" IsComponentControl REG_BINARY 00000000
call :reg "%AK%" KMD_USUEnable REG_DWORD 0
call :reg "%AK%" KMD_RadeonBoostEnabled REG_DWORD 0
call :reg "%AK%" IsAutoDefault REG_BINARY 01000000
call :reg "%AK%" KMD_ChillEnabled REG_DWORD 0
call :reg "%AK%" KMD_DeLagEnabled REG_DWORD 0
call :reg "%AK%" ACE REG_BINARY 3000
call :reg "%AK%" DisableDMACopy REG_DWORD 1
call :reg "%AK%" DisableBlockWrite REG_DWORD 0
call :reg "%AK%" DisableDrmdmaPowerGating REG_DWORD 1
rem -- UMD
call :amd_u AnisoDegree_SET 3020322034203820313600
call :amd_u Main3D_SET 302031203220332034203500
call :amd_u Tessellation_OPTION 3200
call :amd_u Tessellation 3100
call :amd_u AAF 30000000
call :amd_u GI 31000000
call :amd_u CatalystAI 31000000
call :amd_u TemporalAAMultiplier_NA 3100
call :amd_u ForceZBufferDepth 30000000
call :amd_u EnableTripleBuffering 3000
call :amd_u ExportCompressedTex 31000000
call :amd_u PixelCenter 30000000
call :amd_u ZFormats_NA 3100
call :amd_u DitherAlpha_NA 3100
call :amd_u SwapEffect_D3D_SET 3020312032203320342038203900
call :amd_u TFQ 3200
call :amd_u VSyncControl 3100
call :amd_u TextureOpt 30000000
call :amd_u TextureLod 30000000
call :amd_u ASE 3000
call :amd_u ASD 3000
call :amd_u ASTT 3000
call :amd_u AntiAliasSamples 3000
call :amd_u AntiAlias 3100
call :amd_u AnisoDegree 3000
call :amd_u AnisoType 30000000
call :amd_u AntiAliasMapping_SET 3028303A302C313A3029203228303A322C313A3229203428303A342C313A3429203828303A382C313A382900
call :amd_u AntiAliasSamples_SET 3020322034203800
call :amd_u ForceZBufferDepth_SET 3020313620323400
call :amd_u SwapEffect_OGL_SET 3020312032203320342035203620372038203920313120313220313320313420313520313620313700
call :amd_u Tessellation_SET 31203220342036203820313620333220363400
call :amd_u HighQualityAF 3100
call :amd_u DisplayCrossfireLogo 3000
call :amd_u AppGpuId 300078003000310030003000
call :amd_u SwapEffect 30000000
call :amd_u PowerState 3000
call :amd_u AntiStuttering 3100
call :amd_u TurboSync 3000
call :amd_u SurfaceFormatReplacements 3100
call :amd_u EQAA 3000
call :amd_u ShaderCache 3100
call :amd_u MLF 3000
call :amd_u TruformMode_NA 3100
call :amd_u Main3D 3100
call :reg "%AK%\UMD" Main3D_DEF REG_SZ 1
rem -- DXVA
call :amd_d LRTCEnable 30000000
call :amd_d 3to2Pulldown 31000000
call :amd_d MosquitoNoiseRemoval_ENABLE 30000000
call :amd_d Deblocking_ENABLE 30000000
call :amd_d DemoMode 30000000
call :amd_d OverridePA 30000000
call :amd_d DynamicRange 30000000
call :amd_d StaticGamma_ENABLE 30000000
call :amd_d BlueStretch_ENABLE 31000000
call :amd_d BlueStretch 31000000
call :amd_d LRTCCoef 3100300030000000
call :amd_d DynamicContrast_ENABLE 30000000
call :amd_d WhiteBalanceCorrection 30000000
call :amd_d Fleshtone_ENABLE 30000000
call :amd_d ColorVibrance_ENABLE 31000000
call :amd_d ColorVibrance 340030000000
call :amd_d Detail_ENABLE 30000000
call :amd_d Detail 310030000000
call :amd_d Denoise_ENABLE 30000000
call :amd_d TrueWhite 30000000
call :amd_d OvlTheaterMode 30000000
call :amd_d StaticGamma 3100300030000000
call :amd_d InternetVideo 30000000
exit /b 0

:amd_u
call :reg "%AK%\UMD" %1 REG_BINARY %2
exit /b 0

:amd_d
call :reg "%AK%\UMD\DXVA" %1 REG_BINARY %2
exit /b 0

rem ============================================================
rem  EXPERT LAB
rem ============================================================
:mitigations_off
call :log "[EXPERT] mitigations off"
echo.
echo  This lowers system security: Spectre / Meltdown mitigations, SEHOP, CFG,
echo  process mitigations and virtualization-based security are switched off.
choice /c YN /n /m "  Continue? [Y/N]: "
if errorlevel 2 exit /b 0
set "K_MM=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
set "K_KR=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
call :reg "%K_MM%" FeatureSettings REG_DWORD 1
call :reg "%K_MM%" FeatureSettingsOverride REG_DWORD 3
call :reg "%K_MM%" FeatureSettingsOverrideMask REG_DWORD 3
call :reg "%K_MM%" EnableCfg REG_DWORD 0
call :reg "%K_KR%" DisableExceptionChainValidation REG_DWORD 1
call :reg "%K_KR%" KernelSEHOPEnabled REG_DWORD 0
call :reg "%K_KR%" MitigationOptions REG_BINARY 222222222222222222222222222222222222222222222222
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" EnableVirtualizationBasedSecurity REG_DWORD 0
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" HVCIMATRequired REG_DWORD 0
call :reg "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" Enabled REG_DWORD 0
call :log "[OK] mitigations off"
echo  Done. Restart required.
exit /b 0

:defender_off
call :log "[EXPERT] Defender off"
echo.
echo  Turn Tamper Protection OFF in Windows Security first, otherwise Windows
echo  reverts or blocks these changes.
choice /c YN /n /m "  Continue? [Y/N]: "
if errorlevel 2 exit /b 0
set "K_DF=HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"
call :reg "%K_DF%" DisableAntiSpyware REG_DWORD 1
call :reg "%K_DF%" DisableAntiVirus REG_DWORD 1
call :reg "%K_DF%" DisableRoutinelyTakingAction REG_DWORD 1
call :reg "%K_DF%" ServiceKeepAlive REG_DWORD 0
call :reg "%K_DF%\Real-Time Protection" DisableBehaviorMonitoring REG_DWORD 1
call :reg "%K_DF%\Real-Time Protection" DisableIOAVProtection REG_DWORD 1
call :reg "%K_DF%\Real-Time Protection" DisableOnAccessProtection REG_DWORD 1
call :reg "%K_DF%\Real-Time Protection" DisableRealtimeMonitoring REG_DWORD 1
call :reg "%K_DF%\Real-Time Protection" DisableScriptScanning REG_DWORD 1
call :reg "%K_DF%\Reporting" DisableEnhancedNotifications REG_DWORD 1
call :reg "%K_DF%\Spynet" SpynetReporting REG_DWORD 0
call :reg "%K_DF%\Spynet" SubmitSamplesConsent REG_DWORD 2
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" DisableNotifications REG_DWORD 1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\MRT" DontReportInfectionInformation REG_DWORD 1
call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" EnableSmartScreen REG_DWORD 0
%PS% "Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisableScriptScanning $true -DisableBlockAtFirstSeen $true -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue" >>"%LOG%" 2>&1
for %%s in (Sense WdNisSvc WinDefend SecurityHealthService wscsvc) do call :svc %%s
echo.
call :log "[OK] Defender off"
echo  Done. Restart required.
exit /b 0

:ntfs_tweaks
call :log "[EXPERT] NTFS"
call :x "fsutil behavior set memoryusage 2"
call :x "fsutil behavior set mftzone 4"
call :x "fsutil behavior set disablelastaccess 1"
call :x "fsutil behavior set disabledeletenotify 0"
call :x "fsutil behavior set encryptpagingfile 0"
echo  NTFS tweaks applied.
exit /b 0

:memcomp_off
call :log "[EXPERT] memory compression off"
%PS% "Disable-MMAgent -MemoryCompression -PageCombining" >>"%LOG%" 2>&1
echo  Memory compression and page combining disabled. Restart required.
exit /b 0

rem ============================================================
rem  BRANDING
rem ============================================================
:branding
call :log "[BRAND] start"
set "BN=JiffOS"
set "BPC=JIFFOS-PC"
set "BURL=https://raw.githubusercontent.com/giannhs1101/wall/main/jiff_wallpaper.jpg"
set "BDISC=https://discord.gg/fuegoscrims"
set "BROOT=%ProgramData%\JiffOS"
set "BWALL=%BROOT%\wallpaper.jpg"
set "BLOGO=%BROOT%\logo.bmp"
set "ACC=0xff53c800"
set "ACCARGB=0xc400c853"
if not exist "%BROOT%" mkdir "%BROOT%" >nul 2>&1
echo  [*] Wallpaper
if exist "%BWALL%" del /f /q "%BWALL%" >nul 2>&1
curl -fsSL --retry 2 -o "%BWALL%" "%BURL%" >nul 2>&1
if not exist "%BWALL%" %PS% "[Net.ServicePointManager]::SecurityProtocol='Tls12'; Invoke-WebRequest -UseBasicParsing -Uri '%BURL%' -OutFile '%BWALL%'" >nul 2>&1
if exist "%BWALL%" for %%F in ("%BWALL%") do if %%~zF LSS 10240 del /f /q "%BWALL%" >nul 2>&1
if exist "%BWALL%" (
  call :reg "HKCU\Control Panel\Desktop" Wallpaper REG_SZ "%BWALL%"
  call :reg "HKCU\Control Panel\Desktop" WallpaperStyle REG_SZ 10
  call :reg "HKCU\Control Panel\Desktop" TileWallpaper REG_SZ 0
  %PS% "Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class W { [DllImport(\"user32.dll\", SetLastError=true)] public static extern bool SystemParametersInfo(int a, int b, string c, int d); }'; [W]::SystemParametersInfo(20, 0, '%BWALL%', 3) | Out-Null" >nul 2>&1
  echo  [*] Lock screen
  set "K_LK=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
  call :reg "!K_LK!" LockScreenImagePath REG_SZ "%BWALL%"
  call :reg "!K_LK!" LockScreenImageUrl REG_SZ "%BWALL%"
  call :reg "!K_LK!" LockScreenImageStatus REG_DWORD 1
  call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" RotatingLockScreenEnabled REG_DWORD 0
  call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" RotatingLockScreenOverlayEnabled REG_DWORD 0
  call :reg "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" DisableAcrylicBackgroundOnLogon REG_DWORD 1
) else (
  call :log "[FAIL] wallpaper download"
  echo      wallpaper download failed, skipped
)
echo  [*] Theme
set "K_TH=HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
call :reg "!K_TH!" AppsUseLightTheme REG_DWORD 0
call :reg "!K_TH!" SystemUsesLightTheme REG_DWORD 0
call :reg "!K_TH!" ColorPrevalence REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\DWM" AccentColor REG_DWORD %ACC%
call :reg "HKCU\Software\Microsoft\Windows\DWM" ColorizationColor REG_DWORD %ACCARGB%
call :reg "HKCU\Software\Microsoft\Windows\DWM" ColorizationAfterglow REG_DWORD %ACCARGB%
call :reg "HKCU\Software\Microsoft\Windows\DWM" ColorPrevalence REG_DWORD 0
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" AccentColorMenu REG_DWORD %ACC%
call :reg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" StartColorMenu REG_DWORD %ACC%
echo  [*] This PC, boot entry, drive label, PC name, owner
call :keybackup "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /ve /t REG_SZ /d "%BN%" /f >nul 2>&1
bcdedit /set {current} description "%BN%" >nul 2>&1
bcdedit /set {bootmgr} description "%BN% Boot Manager" >nul 2>&1
label C: %BN% >nul 2>&1
if /i not "%COMPUTERNAME%"=="%BPC%" %PS% "Rename-Computer -NewName '%BPC%' -Force -ErrorAction Stop" >nul 2>&1
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" RegisteredOwner REG_SZ "%BN% User"
call :reg "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" RegisteredOrganization REG_SZ "%BN%"
echo  [*] System info logo
set "BP=%TMPD%\jiff_logo.ps1"
>"%BP%"  echo Add-Type -AssemblyName System.Drawing
>>"%BP%" echo $b = New-Object System.Drawing.Bitmap 120,120
>>"%BP%" echo $g = [System.Drawing.Graphics]::FromImage($b)
>>"%BP%" echo $g.SmoothingMode = 'AntiAlias'
>>"%BP%" echo $g.TextRenderingHint = 'AntiAlias'
>>"%BP%" echo $g.Clear([System.Drawing.Color]::FromArgb(14,14,14))
>>"%BP%" echo $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0,200,83),6)
>>"%BP%" echo $g.DrawEllipse($pen,8,8,104,104)
>>"%BP%" echo $f = New-Object System.Drawing.Font('Segoe UI',48,[System.Drawing.FontStyle]::Bold)
>>"%BP%" echo $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0,200,83))
>>"%BP%" echo $sf = New-Object System.Drawing.StringFormat
>>"%BP%" echo $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
>>"%BP%" echo $g.DrawString('J',$f,$br,(New-Object System.Drawing.RectangleF(0,2,120,120)),$sf)
>>"%BP%" echo $b.Save($args[0],[System.Drawing.Imaging.ImageFormat]::Bmp)
powershell -NoProfile -ExecutionPolicy Bypass -File "%BP%" "%BLOGO%" >nul 2>&1
del /f /q "%BP%" >nul 2>&1
set "K_OEM=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
call :reg "!K_OEM!" Manufacturer REG_SZ "%BN%"
call :reg "!K_OEM!" Model REG_SZ "%BN%"
call :reg "!K_OEM!" SupportURL REG_SZ "%BDISC%"
if exist "%BLOGO%" call :reg "!K_OEM!" Logo REG_SZ "%BLOGO%"
set "DESK=%USERPROFILE%\Desktop"
>"%DESK%\%BN% Community.url" echo [InternetShortcut]
>>"%DESK%\%BN% Community.url" echo URL=%BDISC%
echo  [*] Restarting Explorer
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
call :log "[OK] branding done"
echo  Branding applied. Restart to finish.
exit /b 0

rem ============================================================
rem  RESTORE
rem ============================================================
:restore_all
call :restore_services
call :restore_tasks
call :restore_registry
call :restore_devpower
call :restore_power
call :x "bcdedit /deletevalue disabledynamictick"
echo.
echo  Restore finished. Restart required.
exit /b 0

:restore_services
call :log "[RESTORE] services"
set "RC=0"
for /f "delims=" %%f in ('dir /b "%ORIG%\svc\*.txt" 2^>nul') do (
  set "ST="
  set /p "ST=" <"%ORIG%\svc\%%f"
  if defined ST (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%~nf" /v Start /t REG_DWORD /d !ST! /f >nul 2>&1
    set /a RC+=1
  )
)
echo  Services restored: !RC!
exit /b 0

:restore_registry
call :log "[RESTORE] registry"
rem  import shortest names first so parent keys are applied before their sub keys
%PS% "Get-ChildItem '%ORIG%\reg\*.reg' | Sort-Object { $_.BaseName.Length } | ForEach-Object { $_.FullName }" >"%TMPD%\regfiles.txt" 2>nul
for /f "usebackq delims=" %%f in ("%TMPD%\regfiles.txt") do reg import "%%f" >nul 2>&1
rem  delete values that did not exist before
if exist "%ORIG%\created.txt" (
  for /f "usebackq tokens=1,* delims=|" %%a in ("%ORIG%\created.txt") do reg delete "%%a" /v "%%b" /f >nul 2>&1
)
echo  Registry restored.
exit /b 0

:forget_originals
echo.
echo  This deletes the saved original values. After this the Restore menu
echo  can no longer return to the state before the first run.
choice /c YN /n /m "  Delete saved originals? [Y/N]: "
if errorlevel 2 exit /b 0
rd /s /q "%ORIG%" >nul 2>&1
for %%d in ("%ORIG%" "%ORIG%\reg" "%ORIG%\svc") do if not exist "%%~d" mkdir "%%~d" >nul 2>&1
set "LASTKB="
call :log "[RESTORE] originals cleared"
echo  Done.
exit /b 0

rem ============================================================
rem  HELPERS
rem ============================================================
:reg
rem  call :reg "KEY" "NAME" TYPE "DATA"
call :keybackup "%~1"
reg query "%~1" /v "%~2" >nul 2>&1
if errorlevel 1 >>"%ORIG%\created.txt" echo %~1^|%~2
reg add "%~1" /v "%~2" /t %~3 /d "%~4" /f >nul 2>&1
if errorlevel 1 (call :log "[FAIL] %~1 : %~2") else (call :log "[OK]   %~2")
exit /b 0

:keybackup
rem  exports a key the first time it is touched
set "KB=%~1"
if "!KB!"=="!LASTKB!" exit /b 0
set "LASTKB=!KB!"
set "FN=!KB!"
set "FN=!FN:\=_!"
set "FN=!FN: =_!"
set "FN=!FN:/=_!"
if exist "%ORIG%\reg\!FN!.reg" exit /b 0
if exist "%ORIG%\reg\!FN!.nokey" exit /b 0
reg export "!KB!" "%ORIG%\reg\!FN!.reg" /y >nul 2>&1
if errorlevel 1 (
  >"%ORIG%\reg\!FN!.nokey" echo x
) else (
  call :log "[BK] !KB!"
)
exit /b 0

:x
rem  call :x "command"   - runs a command (no double quotes inside) and logs the result
call :log "[RUN] %~1"
%~1 >>"%LOG%" 2>&1
if errorlevel 1 (call :log "[FAIL] exit=%errorlevel%") else (call :log "[OK]")
exit /b 0

:log
>>"%LOG%" echo [%time%] %~1
exit /b 0

:press
echo.
pause
exit /b 0

:show_paths
echo.
echo  Log folder : %LOGDIR%
echo  This log   : %LOG%
echo  Originals  : %ORIG%
echo  Power plan : %JP%
exit /b 0

:detect
set "OSNAME=Windows"
set "DISPLAYVER="
set "BUILD=0"
set "CPU=Unknown"
set "GPU=Unknown"
set "HAS_NV=0"
set "HAS_AMD=0"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul ^| findstr /i "ProductName"') do set "OSNAME=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2^>nul ^| findstr /i "DisplayVersion"') do set "DISPLAYVER=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "BUILD=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0" /v ProcessorNameString 2^>nul ^| findstr /i "ProcessorNameString"') do set "CPU=%%b"
for /f "usebackq delims=" %%g in (`%PS% "(Get-CimInstance Win32_VideoController | ForEach-Object Name) -join ' / '"`) do set "GPU=%%g"
if %BUILD% GEQ 22000 set "OSNAME=!OSNAME:Windows 10=Windows 11!"
call :has_word "!GPU!" nvidia && set "HAS_NV=1"
call :has_word "!GPU!" geforce && set "HAS_NV=1"
call :has_word "!GPU!" quadro && set "HAS_NV=1"
call :has_word "!GPU!" radeon && set "HAS_AMD=1"
call :has_word "!GPU!" amd && set "HAS_AMD=1"
exit /b 0

:has_word
rem  call :has_word "text" word   - errorlevel 0 when word occurs in text (case-insensitive)
set "HW=%~1"
if not "!HW:%~2=!"=="!HW!" exit /b 0
exit /b 1

:header
echo ============================================================
echo   !VER!
echo ============================================================
echo   OS  : !OSNAME! !DISPLAYVER!  ^(build !BUILD!^)
echo   CPU : !CPU!
echo   GPU : !GPU!
echo   Log : !LOG!
echo ------------------------------------------------------------
exit /b 0
