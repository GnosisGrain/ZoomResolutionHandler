# Enhanced PowerShell script for managing display settings
param(
    [switch]$Save,
    [switch]$Restore,
    [switch]$Configure,
    [int]$EntryNumber
)

# Determine the script directory
$scriptPath = if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
    [System.IO.Path]::GetDirectoryName([Environment]::GetCommandLineArgs()[0])
}

# Function to write log messages to a file and console
function Write-LogMessage {
    param([string]$Message)
    $logFile = Join-Path $scriptPath "display_settings_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host "$($timestamp) - $($Message)"
}

# Function to show help information
function Show-Help {
    Write-Host "Help Information:"
    Write-Host "Use -Save to save current display settings."
    Write-Host "Use -Restore to restore display settings from a saved state."
    Write-Host "Use -Configure to configure system tasks."
    Write-Host "Use -EntryNumber to specify an entry for restoration."
}

# Function to save display settings to CSV
function Save-DisplaySettings {
    $csvFile = Join-Path $scriptPath "display_settings.csv"
    $batFile = Join-Path $scriptPath "restore_display_settings.bat"
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    
    $csvData = $screens | ForEach-Object {
        [PSCustomObject]@{
            DeviceName    = $_.DeviceName
            DisplayIndex  = $_.Primary -replace 'True', '1' -replace 'False', '0'
            Resolution    = "$($_.Bounds.Width)x$($_.Bounds.Height)"
            WorkingArea   = "$($_.WorkingArea.Width)x$($_.WorkingArea.Height)"
            Primary       = $_.Primary
            BitsPerPixel  = $_.BitsPerPixel
            Orientation   = $_.Bounds.Orientation  # Assuming orientation is accessible; adjust if not
            RefreshRate   = $_.RefreshRate
            PhysicalSize  = "$($_.PhysicalSize.Width)x$($_.PhysicalSize.Height)"
            ScalingFactor = $_.ScalingFactor
        }
    }
    
    $csvData | Export-Csv -Path $csvFile -NoTypeInformation
    Write-LogMessage "Display settings saved to $csvFile"

    # Create or update BAT file to run with administrative privileges
    $batContent = @"
@echo off
:: Elevate the batch process to run as administrator
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject("Shell.Application") > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    cd /d "%~dp0"
:: Start PowerShell with the Restore flag
powershell -ExecutionPolicy Bypass -File "$scriptPath\screen_resolution_handlers.ps1" -Restore
"@
    $batContent | Out-File -FilePath $batFile -Encoding ASCII
    Write-LogMessage "BAT file created at $batFile"
}

# Function to list and select settings from CSV for restoration
function ListAndSelectSettings {
    $csvFile = Join-Path $scriptPath "display_settings.csv"
    if (Test-Path $csvFile) {
        $settings = Import-Csv -Path $csvFile
        for ($i = 0; $i -lt $settings.Count; $i++) {
            Write-Host "$($i): $($settings[$i].DeviceName), $($settings[$i].Bounds), $($settings[$i].Primary)"
        }
        $selected = Read-Host "Enter the number of the setting to restore"
        return [int]$selected
    }
    else {
        Write-Host "No saved display settings found."
        return $null
    }
}

# Function to restore display settings from CSV
function Restore-DisplaySettings {
    param([int]$entryIndex)
    $csvFile = Join-Path $scriptPath "display_settings.csv"
    if (Test-Path $csvFile) {
        $settings = Import-Csv -Path $csvFile
        if ($entryIndex -ge 0 -and $entryIndex -lt $settings.Count) {
            $selectedSetting = $settings[$entryIndex]
            Write-LogMessage "Restoring settings for $($selectedSetting.DeviceName) to resolution $($selectedSetting.Bounds)"
            # Placeholder: insert the command to actually apply these settings, possibly using a utility or script
        }
        else {
            Write-LogMessage "Invalid entry number."
        }
    }
    else {
        Write-LogMessage "No saved display settings found."
    }
}

function Configure-SchedulerTasks {
    Write-LogMessage "Functionality to configure scheduler tasks goes here."
}

try {
    if ($Restore -and $EntryNumber) {
        Restore-DisplaySettings -entryIndex $EntryNumber
    }
    elseif ($Restore) {
        $entryIndex = ListAndSelectSettings
        if ($null -ne $entryIndex) {
            Restore-DisplaySettings -entryIndex $entryIndex
        }
    }
    elseif ($Save) {
        Save-DisplaySettings
    }
    elseif ($Configure) {
        Configure-SchedulerTasks
    }
    else {
        Show-Help
    }
}
catch {
    Write-LogMessage "An error occurred: $_"
    throw $_
}
