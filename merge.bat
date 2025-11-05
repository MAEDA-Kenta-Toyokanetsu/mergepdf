@echo off
setlocal ENABLEDELAYEDEXPANSION
chcp 65001 >nul

REM --- paths ---
set "BASE=%~dp0"
set "SCRIPTS=%BASE%scripts"
set "PY=%SCRIPTS%\python0313\python.exe"
set "SCRIPT=%SCRIPTS%\merge.py"
set "LOGDIR=%SCRIPTS%\logs"

if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1

REM --- timestamp for logs & output (yyyyMMdd_HHmmss) ---
for /f %%t in ('powershell -NoProfile -Command "(Get-Date).ToString(\"yyyyMMdd_HHmmss\")"') do set "TS=%%t"
set "LOG=%LOGDIR%\merge_%TS%.log"

REM --- sanity checks ---
if not exist "%PY%" (
  echo [ERROR] python not found: "%PY%" > "%LOG%"
  goto :SHOWLOG
)
if not exist "%SCRIPT%" (
  echo [ERROR] merge.py not found: "%SCRIPT%" > "%LOG%"
  goto :SHOWLOG
)

REM --- self check (version / pypdf) ---
"%PY%" -X utf8 -c "import sys;print('Python',sys.version)"  1>>"%LOG%" 2>&1
"%PY%" -X utf8 -c "import pypdf,sys;print('pypdf',pypdf.__version__)"  1>>"%LOG%" 2>&1

REM === 1) Drag & Drop (args present) ===
if not "%~1"=="" (
  set "FILES="
  set "FIRSTDIR="
  for %%A in (%*) do (
    if /I "%%~xA"==".pdf" (
      if not defined FIRSTDIR set "FIRSTDIR=%%~dpA"
      if /I not "%%~dpA"=="!FIRSTDIR!" (
        echo [ERROR] PDFs from multiple folders are not allowed. >> "%LOG%"
        set "RC=2"
        goto :SHOWLOG
      )
      set "BN=%%~nA"
      REM exclude any 'merged*.pdf'
      if /I not "!BN:~0,6!"=="merged" (
        set "FILES=!FILES! "%%~fA""
      )
    )
  )
  if not defined FILES (
    echo [ERROR] no mergeable PDFs specified. >> "%LOG%"
    set "RC=3"
    goto :SHOWLOG
  )
  set "OUT=!FIRSTDIR!merged_%TS%.pdf"
  echo [INFO] mode=DND >> "%LOG%"
  echo [INFO] out="!OUT!" >> "%LOG%"
  echo [INFO] files=!FILES! >> "%LOG%"
  "%PY%" -X utf8 "%SCRIPT%" --files !FILES! --out "!OUT!"  1>>"%LOG%" 2>&1
  set "RC=%ERRORLEVEL%"
  goto :SHOWLOG
)

REM === 2) Double-click (no args) ===
set "TARGETDIR=%~dp0"
set "OUT=%TARGETDIR%merged_%TS%.pdf"

REM enumerate PDFs in folder and exclude merged*.pdf
set "FILES="
for %%F in ("%TARGETDIR%*.pdf") do (
  set "BN=%%~nF"
  if /I not "!BN:~0,6!"=="merged" (
    set "FILES=!FILES! "%%~fF""
  )
)

if not defined FILES (
  echo [INFO] mode=DOUBLECLICK >> "%LOG%"
  echo [ERROR] no PDFs found in: "%TARGETDIR%" >> "%LOG%"
  set "RC=1"
  goto :SHOWLOG
)

echo [INFO] mode=DOUBLECLICK >> "%LOG%"
echo [INFO] out="%OUT%" >> "%LOG%"
echo [INFO] files=!FILES! >> "%LOG%"
"%PY%" -X utf8 "%SCRIPT%" --files !FILES! --out "%OUT%"  1>>"%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
goto :SHOWLOG

:SHOWLOG
echo ================ [LOG START] ================
powershell -NoProfile -Command ^
  "$OutputEncoding = [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8; " ^
  "Get-Content -LiteralPath '%LOG%' -Encoding UTF8 | Out-Host"
echo ================= [LOG END] ================
if not defined RC set "RC=0"
echo [INFO] exit code: %RC%
echo [INFO] log saved to: %LOG%
endlocal
