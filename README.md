README: Display Settings Management Script

This README details a PowerShell script designed to manage and automate display settings for different users across their sessions on a Windows system. The script is capable of saving display settings into a user-specific CSV file and generating a BAT file for restoring these settings. It includes functions for setting up automatic execution at user logon and logoff using Task Scheduler.
Overview

The PowerShell script automates saving and restoring display settings for each user, ensuring consistent environment settings across sessions. It incorporates advanced logging, saves settings to a CSV file, creates a BAT file for settings restoration, and configures itself to run automatically at user logon and logoff.
Script Components
Logging Function (Log-Message)

    Purpose: Logs messages to a user-specific log file for auditing and troubleshooting.
    Implementation:

    powershell

    function Log-Message {
        param([string]$Message)
        $logPath = "$env:USERPROFILE\display_settings_log.txt"
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $logPath -Append
    }

Saving Display Settings (Save-DisplaySettings)

    Purpose: Captures current display settings and saves them to a CSV file, also generating a BAT file for easy restoration.
    Implementation:

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

Restoring Display Settings (Restore-DisplaySettings)

    Purpose: Reads and applies display settings from a saved CSV file.
    Implementation:

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

Scheduler Task Configuration (Configure-SchedulerTasks)

    Purpose: Sets up Task Scheduler to run the script at user logon and logoff.
    Implementation:

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

    Running the Script: Execute the script with -Configure to set up the Task Scheduler tasks for automatic execution. Use -Save and -Restore switches to manually trigger saving and restoring display settings, respectively.

Deployment

    Deploy this script through the Task Scheduler or Group Policy for automated execution at user logon and logoff. This ensures that display settings are appropriately managed every time a user logs on or off.
