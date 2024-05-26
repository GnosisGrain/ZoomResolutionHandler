@ -6,10 +6,21 @@ param(
    [switch]$Configure
)

# Helper function to log messages to the console
function Log-Message {
# Determine the directory of the currently running script/executable
$scriptPath = if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
    [System.IO.Path]::GetDirectoryName([Environment]::GetCommandLineArgs()[0])
}

# Function to log messages to a file and console
function Write-LogMessage {
    param([string]$Message)
    Write-Host $Message  # Using Write-Host for immediate console output
    $logFile = Join-Path -Path $scriptPath -ChildPath "display_settings_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host $Message
}

# Function to show help information
@ -20,71 +31,75 @@ function Show-Help {
    Write-Host "Use -Configure to configure system tasks."
}

# Main script logic based on provided parameters
try {
    # Defaulting to Save if no parameters are provided
    if (!$Save -and !$Restore -and !$Configure) {
        $Save = $true
        Log-Message "No operation specified. Defaulting to -Save."
    }

    if ($Configure) {
        Log-Message "Configure operation selected."
        Configure-SchedulerTasks
    } elseif ($Save) {
        Log-Message "Save operation selected."
        Save-DisplaySettings
    } elseif ($Restore) {
        Log-Message "Restore operation selected."
        Restore-DisplaySettings
    } else {
        Log-Message "No valid operation specified. Use -Save to save settings, -Restore to restore settings, or -Configure to setup tasks."
        Write-Host "Running help..."
        Show-Help
    }
} catch {
    Log-Message "An error occurred: $_"
    throw
}

# Function definitions for saving and restoring settings (placeholders, replace with your actual functionality)
# Function to save display settings to a CSV file and create a BAT file
function Save-DisplaySettings {
    $settingsPath = "$env:USERPROFILE\display_settings.csv"
    $batPath = "$env:USERPROFILE\restore_display_settings.bat"
    $csvFile = Join-Path -Path $scriptPath -ChildPath "display_settings.csv"
    $batFile = Join-Path -Path $scriptPath -ChildPath "restore_display_settings.bat"
    
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $csvData = $screens | ForEach-Object {
        $props = @{
            DeviceName = $_.DeviceName
            Bounds = $_.Bounds.ToString()
            WorkingArea = $_.WorkingArea.ToString()
            Primary = $_.Primary
            DeviceName   = $_.DeviceName
            Bounds       = $_.Bounds.ToString()
            WorkingArea  = $_.WorkingArea.ToString()
            Primary      = $_.Primary
            BitsPerPixel = $_.BitsPerPixel
        }
        New-Object PSObject -Property $props
    }
    $csvData | Export-Csv -Path $settingsPath -NoTypeInformation
    Log-Message "Display settings saved to $settingsPath"
    $csvData | Export-Csv -Path $csvFile -NoTypeInformation
    Write-LogMessage "Display settings saved to $csvFile"
    
    $batContent = "echo off`r`necho Restoring display settings...`r`npowershell -File '$env:USERPROFILE\restore_display_settings.ps1' -Restore"
    $batContent | Out-File -FilePath $batPath -Encoding ASCII
    Log-Message "BAT file created at $batPath"
    $batContent = "echo off`r`necho Restoring display settings...`r`npowershell -File `"$batFile`" -Restore"
    $batContent | Out-File -FilePath $batFile -Encoding ASCII
    Write-LogMessage "BAT file created at $batFile"
}

# Function to restore display settings from the CSV file
function Restore-DisplaySettings {
    $settingsPath = "$env:USERPROFILE\display_settings.csv"
    if (Test-Path $settingsPath) {
        $settings = Import-Csv -Path $settingsPath
    $csvFile = Join-Path -Path $scriptPath -ChildPath "display_settings.csv"
    if (Test-Path $csvFile) {
        $settings = Import-Csv -Path $csvFile
        foreach ($setting in $settings) {
            Log-Message "Restoring settings for $($setting.DeviceName) to resolution $($setting.Bounds)"
            Write-LogMessage "Restoring settings for $($setting.DeviceName) to resolution $($setting.Bounds)"
        }
        Log-Message "Display settings restored from $settingsPath"
    } else {
        Log-Message "No saved display settings found at $settingsPath"
        Write-LogMessage "Display settings restored from $csvFile"
    }
    else {
        Write-LogMessage "No saved display settings found at $csvFile"
    }
}

# Placeholder function to configure scheduler tasks
function Configure-SchedulerTasks {
    Log-Message "Functionality to configure scheduler tasks goes here."
    Write-LogMessage "Functionality to configure scheduler tasks goes here."
}

# Main script logic based on provided parameters
try {
    if (!$Save -and !$Restore -and !$Configure) {
        $Save = $true
        Write-LogMessage "No operation specified. Defaulting to -Save."
    }

    if ($Configure) {
        Write-LogMessage "Configure operation selected."
        Set-SchedulerTasks  # Updated function call
    }
    elseif ($Save) {
        Save-DisplaySettings
    }
    elseif ($Restore) {
        Restore-DisplaySettings
    }
    else {
        Write-LogMessage "No valid operation specified. Use -Save, -Restore, or -Configure."
        Show-Help
    }
}
catch {
    Write-LogMessage "An error occurred: $_"
    throw $_
}

