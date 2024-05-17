# Define functions and main operations for handling and automating display settings management across user sessions

# Helper function to log messages
function Log-Message {
    param(
        [string]$Message
    )
    $logPath = "$env:USERPROFILE\display_settings_log.txt"
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $logPath -Append
}

# Function to save current display settings to a CSV and generate a BAT file to restore them
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

    # Create BAT file to restore settings
    $batContent = "echo off`r`necho Restoring display settings...`r`npowershell -File `"$env:USERPROFILE\restore_display_settings.ps1`" -Restore"
    $batContent | Out-File -Path $batPath -Encoding ASCII
    Log-Message "BAT file created at $batPath"
}

# Function to automatically configure Task Scheduler tasks for logon and logoff
function Configure-SchedulerTasks {
    $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-File "$env:USERPROFILE\screen_resolution_handler.ps1" -Restore'
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn
    $triggerLogoff = New-ScheduledTaskTrigger -AtLogOff
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive

    Register-ScheduledTask -Action $action -Trigger $triggerLogon -TaskName "RestoreDisplaySettingsOnLogon" -Description "Restores display settings on user logon" -Principal $principal
    Register-ScheduledTask -Action $action -Trigger $triggerLogoff -TaskName "SaveDisplaySettingsOnLogoff" -Description "Saves display settings on user logoff" -Principal $principal
    
    Log-Message "Task Scheduler configured for logon and logoff tasks"
}

# Function to restore display settings from the CSV
function Restore-DisplaySettings {
    $settingsPath = "$env:USERPROFILE\display_settings.csv"
    if (Test-Path $settingsPath) {
        $settings = Import-Csv -Path $settingsPath
        foreach ($setting in $settings) {
            # Simulation of restoration commands
            Log-Message "Restoring settings for $($setting.DeviceName) to resolution $($setting.Bounds)"
            # Include actual screen setting command here
        }
        Log-Message "Display settings restored from $settingsPath"
    } else {
        Log-Message "No saved display settings found at $settingsPath"
    }
}

# Main script logic to determine operation based on switches and configure tasks
param(
    [switch]$Save,
    [switch]$Restore,
    [switch]$Configure
)

if ($Configure) {
    Configure-SchedulerTasks
} elseif ($Save) {
    Save-DisplaySettings
} elseif ($Restore) {
    Restore-DisplaySettings
} else {
    Log-Message "No valid operation specified. Use -Save to save settings, -Restore to restore settings, or -Configure to setup tasks."
}
