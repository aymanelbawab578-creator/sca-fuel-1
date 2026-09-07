@echo off
setlocal enableextensions enabledelayedexpansion

:: ضبط المسار الأساسي إلى مكان هذا الملف
set "ROOT=%~dp0"
set "BACKEND=%ROOT%backend"
set "FRONTEND=%ROOT%frontend"
set "EXE=%FRONTEND%\build\windows\x64\runner\Release\sca_fuel.exe"

:: تشغيل الخادم في نافذة جديدة مصغرة
echo Starting backend...
start "SCA Fuel backend" /min cmd /c "cd /d "%BACKEND%" && call .venv\Scripts\activate && uvicorn app.main:app --host 127.0.0.1 --port 8000"

:: انتظر قليلًا للتأكد من أن السيرفر بدأ
timeout /t 3 /nobreak >nul

if exist "%EXE%" (
  echo Starting frontend...
  start "SCA Fuel frontend" "%EXE%"
) else (
  echo ERROR: frontend executable not found: "%EXE%"
  echo Please build the windows release first with:
  echo     flutter build windows --release
  pause
)
