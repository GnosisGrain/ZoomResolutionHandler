@echo off
setlocal enabledelayedexpansion

:: Define the path to the PowerShell script and CSV file
set scriptPath=C:\Users\Doc\screen_resolutions_handler
set csvFile=%scriptPath%\display_settings.csv

:: Check if the CSV file exists
if not exist "%csvFile%" (
    echo No saved display settings found.
    pause
    exit /b
)

:: List all saved display settings
echo Saved display settings:
set index=0
for /f "tokens=* delims=" %%i in ('powershell -Command "Import-Csv -Path ''%csvFile%'' | ForEach-Object { ''!index! - $($_.DeviceName), $($_.Bounds), Primary: $($_.Primary)''; $global:index++ }"') do (
    echo %%i
    set /a index+=1
)

:: Prompt the user to select a setting
set /p selectedIndex=Enter the number of the setting to restore:

:: Validate the input
set validInput=0
for /l %%i in (0,1,!index!) do (
    if "!selectedIndex!"=="%%i" (
        set validInput=1
    )
)

if "!validInput!"=="0" (
    echo Invalid selection.
    pause
    exit /b
)

:: Restore the selected display setting
echo Restoring display settings...
powershell -ExecutionPolicy Bypass -File "%scriptPath%\screen_resolution_handlers.ps1" -Restore -EntryNumber !selectedIndex!
pause
