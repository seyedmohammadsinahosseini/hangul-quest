@echo off
REM One-time setup for Hangul Quest (Windows).
REM Generates the android/ + ios/ folders, fetches packages and patches the
REM AndroidManifest so the Korean TTS engine is visible on Android 11+.

cd /d "%~dp0"

echo [1/3] Creating platform folders...
call flutter create . --project-name hangul_quest --org com.hangulquest --platforms android,ios
if errorlevel 1 goto :fail

echo [2/3] Fetching packages...
call flutter pub get
if errorlevel 1 goto :fail

echo [3/3] Patching AndroidManifest.xml for text-to-speech...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='android\app\src\main\AndroidManifest.xml';" ^
  "$m=Get-Content $p -Raw;" ^
  "if ($m -notmatch 'TTS_SERVICE') {" ^
  "  $q='    <queries>`n        <intent>`n            <action android:name=\"android.intent.action.TTS_SERVICE\" />`n        </intent>`n    </queries>`n';" ^
  "  $m=$m -replace '(<manifest[^>]*>\s*)', ('$1' + $q);" ^
  "  Set-Content $p $m -NoNewline;" ^
  "  Write-Host 'Manifest patched.'" ^
  "} else { Write-Host 'Manifest already patched.' }"

echo.
echo Done. Now plug in a phone (USB debugging on) or start an emulator and run:
echo     flutter run
goto :eof

:fail
echo.
echo Setup failed. Make sure Flutter is installed and on your PATH:  flutter doctor
exit /b 1
