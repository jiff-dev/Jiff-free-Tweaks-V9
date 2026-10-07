@echo off
setlocal
title Jiff Tweaks
cd /d "%~dp0"

rem -- needs administrator rights (changes system settings)
fltmc >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
  exit /b
)

if not exist "%~dp0app\server.ps1" (
  echo Missing file: app\server.ps1
  echo Extract the whole zip first, then run Jiff Tweaks.bat from the extracted folder.
  pause
  exit /b 1
)
if not exist "%~dp0engine\Jiff_Tweaks_V9.bat" (
  echo Missing file: engine\Jiff_Tweaks_V9.bat
  echo Extract the whole zip first, then run Jiff Tweaks.bat from the extracted folder.
  pause
  exit /b 1
)

rem -- starts the local service and opens the app window; this console hides itself
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0app\server.ps1"
exit /b 0
