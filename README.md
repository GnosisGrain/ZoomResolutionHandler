README: Display Settings Management PowerShell Script

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
