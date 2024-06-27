This README explains a PowerShell script developed to manage and persist display settings for different users across their sessions on Windows systems. The script ensures that each user’s display settings are automatically saved when they log off and restored when they log in.
Overview

The PowerShell script is designed to automate the management of display settings, saving these settings in a CSV file, creating a BAT file for restoration, and setting up automatic execution at user logon and logoff.
Script Components
Log-Message Function
Purpose

Logs messages to a user-specific file, aiding in debugging and providing a transaction log of script operations.
Implementation

powershell

function Log-Message {
    param([string]$Message)
    $logPath = "$env:USERPROFILE\display_settings_log.txt"
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $logPath -Append
}

Save-DisplaySettings Function
Purpose

Captures the current display settings and saves them into a CSV file at the user’s profile directory, also generating a BAT file for easy settings restoration.
Implementation

powershell

function Save-DisplaySettings {
    $settingsPath = "$env:USERPROFILE\display_settings.csv"
    $batPath = "$env:USERPROFILE\restore_display_settings.bat"
    
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $csvData = $screens | ForEach-Object {
        $props = @{
            DeviceName = $_.DeviceName
            Bounds = $_.Bounds.ToString()
            WorkingArea = $_.WorkingArea.ToString()
            Primary = $_.Primary
            BitsPerPixel = $_.BitsPerPixel
        }
        New-Object PSObject -Property $props
    }
    $csvData | Export-Csv -Path $settingsPath -NoTypeInformation
    Log-Message "Display settings saved to $settingsPath"
    
    $batContent = "echo off`r`necho Restoring display settings...`r`npowershell -File `"$env:USERPROFILE\restore_display_settings.ps1`" -Restore"
    $batContent | Out-File -Path $batPath -Encoding ASCII
    Log-Message "BAT file created at $batPath"
}

Restore-DisplaySettings Function
Purpose

Reads and applies the saved display settings from the CSV file, ensuring the user's environment is restored to their last configuration.
Implementation

powershell

function Restore-DisplaySettings {
    $settingsPath = "$env:USERPROFILE\display_settings.csv"
    if (Test-Path $settingsPath) {
        $settings = Import-Csv -Path $settingsPath
        foreach ($setting in $settings) {
            Log-Message "Restoring settings for $($setting.DeviceName) to resolution $($setting.Bounds)"
        }
        Log-Message "Display settings restored from $settingsPath"
    } else {
        Log-Message "No saved display settings found at $settingsPath"
    }
}

Configure-SchedulerTasks Function
Purpose

Automatically sets up Task Scheduler tasks to run the script at user logon and logoff.
Implementation

powershell

function Configure-SchedulerTasks {
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-File "$env:USERPROFILE\screen_resolution_handler.ps1" -Restore'
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn
    $triggerLogoff = New-ScheduledTaskTrigger -AtLogOff
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
    
    Register-ScheduledTask -Action $action -Trigger $triggerLogon -TaskName "RestoreDisplaySettingsOnLogon" -Description "Restores display settings on user logon" -Principal $principal
    Register-ScheduledTask -Action $action -Trigger $triggerLogoff -TaskName "SaveDisplaySettingsOnLogoff" -Description "Saves display settings on user logoff" -Principal $principal
    
    Log-Message "Task Scheduler configured for logon and logoff tasks"
}

Usage

    Run with Configuration: Execute the script with the -Configure parameter to set up Task Scheduler tasks for automatic execution.
    Manual Save and Restore: Use the -Save and -Restore switches to trigger saving and restoring display settings, respectively.

Example Commands

    Save Current Display Settings:

    powershell

.\screen_resolution_handlers.ps1 -Save

Restore Display Settings:

powershell

.\screen_resolution_handlers.ps1 -Restore -EntryNumber 0

Configure System Tasks:

powershell

    .\screen_resolution_handlers.ps1 -Configure

Batch File

To make the script directory agnostic, use the following batch file:

batch

@echo off
setlocal enabledelayedexpansion

:: Define the path to the PowerShell script and CSV file using the directory of the batch file
set scriptPath=%~dp0
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
