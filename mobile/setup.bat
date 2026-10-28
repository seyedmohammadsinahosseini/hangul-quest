@echo off
REM One-time setup for Hangul Quest (Windows).
REM Generates the android/ + ios/ folders, patches AndroidManifest.xml so the
REM Korean TTS engine is visible on Android 11+, then verifies the patch.

setlocal
cd /d "%~dp0"
set MANIFEST=android\app\src\main\AndroidManifest.xml
set QUERIES=%TEMP%\hq_tts_queries.xml

echo [1/4] Creating platform folders...
call flutter create . --project-name hangul_quest --org com.hangulquest --platforms android,ios
if errorlevel 1 goto :fail

echo [2/4] Patching AndroidManifest.xml for text-to-speech...
findstr /c:"android.intent.action.TTS_SERVICE" "%MANIFEST%" >nul 2>&1
if not errorlevel 1 (
  echo       already patched.
  goto :verify
)

REM Write the block to a temp file so no XML has to survive cmd quoting.
> "%QUERIES%" echo     ^<queries^>
>>"%QUERIES%" echo         ^<intent^>
>>"%QUERIES%" echo             ^<action android:name="android.intent.action.TTS_SERVICE" /^>
>>"%QUERIES%" echo         ^</intent^>
>>"%QUERIES%" echo     ^</queries^>

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%MANIFEST%'; $q=Get-Content '%QUERIES%' -Raw;" ^
  "$m=[IO.File]::ReadAllText($p); $i=$m.IndexOf('>');" ^
  "if ($i -lt 0) { exit 1 }" ^
  "$m=$m.Substring(0,$i+1) + [Environment]::NewLine + $q + $m.Substring($i+1);" ^
  "[IO.File]::WriteAllText($p, $m, (New-Object Text.UTF8Encoding($false)));" ^
  "Write-Host '      patched.'"
del "%QUERIES%" >nul 2>&1

:verify
findstr /c:"android.intent.action.TTS_SERVICE" "%MANIFEST%" >nul 2>&1
if errorlevel 1 (
  echo.
  echo ERROR: AndroidManifest.xml still has no queries block for TTS.
  echo        Audio buttons will do nothing on Android 11+. Add this inside
  echo        the ^<manifest^> element by hand:
  echo            ^<queries^>^<intent^>^<action android:name="android.intent.action.TTS_SERVICE" /^>^</intent^>^</queries^>
  goto :fail
)

echo [3/4] Fetching packages...
call flutter pub get
if errorlevel 1 goto :fail

echo [4/4] Sanity checks...
call flutter analyze
call flutter test

echo.
echo Done. Plug in a phone ^(USB debugging on^) or start an emulator, then run:
echo     flutter run
echo.
echo If a tap shows a hint instead of speaking, install the Korean voice:
echo   Android: Settings ^> System ^> Languages ^& input ^> Text-to-speech
echo   iOS:     Settings ^> Accessibility ^> Spoken Content ^> Voices ^> Korean
goto :eof

:fail
echo.
echo Setup failed. Make sure Flutter is installed and on your PATH:  flutter doctor
exit /b 1
