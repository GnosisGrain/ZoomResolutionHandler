# Enhanced PowerShell script for managing display settings

param(
    [switch]$Save,
    [switch]$Restore,
    [switch]$Configure
)

# Helper function to log messages to the console
function Log-Message {
    param([string]$Message)
    Write-Host $Message  # Using Write-Host for immediate console output
}

# Function to show help information
function Show-Help {
    Write-Host "Help Information:"
    Write-Host "Use -Save to save current display settings."
    Write-Host "Use -Restore to restore display settings from a saved state."
    Write-Host "Use -Configure to configure system tasks."
}

# Main script logic based on provided parameters
try {
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
function Save-DisplaySettings {
    Log-Message "Functionality to save display settings goes here."
}

function Restore-DisplaySettings {
    Log-Message "Functionality to restore display settings goes here."
}

function Configure-SchedulerTasks {
    Log-Message "Functionality to configure scheduler tasks goes here."
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
    
    $batContent = "echo off`r`necho Restoring display settings...`r`npowershell -File '$env:USERPROFILE\restore_display_settings.ps1' -Restore"
    $batContent | Out-File -FilePath $batPath -Encoding ASCII
    Log-Message "BAT file created at $batPath"
}

# Function to restore display settings from the CSV
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

# Main script logic based on provided parameters
try {
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
        # Optionally, you could provide a default behavior here instead of throwing an error
        # throw "No valid operation specified."
    }
} catch {
    Log-Message "An error occurred: $_"
    throw
}

function Show-Help {
    Write-Host "Help Information:"
    Write-Host "Use -Save to save current display settings."
    Write-Host "Use -Restore to restore display settings from a saved state."
    Write-Host "Use -Configure to configure system tasks."
}
