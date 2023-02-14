@echo off

set "scriptPath=\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsTask\script\OverlayTimer.ps1"
set "cmd=. %scriptPath%"
set "cmd=%cmd%; Start-OverlayTimer"
set "cmd=%cmd% -Seconds %~1"

if "%~2" EQU "--whatif" goto whatif
if "%~2" EQU "" goto run

set "cmd=%cmd% -Command:""%~2"""

if "%~3" EQU "--whatif" goto whatif

:run
echo Executing
cmd /c powershell "%cmd%"
exit /b

:whatif
echo %cmd%
exit /b

