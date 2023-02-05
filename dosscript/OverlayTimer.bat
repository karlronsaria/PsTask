@echo off

set "scriptPath=\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTask\script\OverlayTimer.ps1"
set "cmd=. %scriptPath%"
set "cmd=%cmd%; Start-OverlayTimer"
set "cmd=%cmd%; -Seconds %~1"
set "cmd=%cmd%; -Command "%~2""

if "%3" EQU "--whatif" goto whatif

echo Executing
exit /b

:whatif
echo %cmd%
exit /b

:: powershell %cmd%

