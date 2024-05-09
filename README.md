ZoomResolutionsHandler.ps1 Documentation 

This PowerShell script is designed to manage screen resolutions automatically during Zoom sessions. It detects when Zoom is active and adjusts the screen resolution to predefined settings, then restores the original resolution once Zoom is closed. 

Requirements 

    Windows Operating System with PowerShell 5.1 or higher 

    Administrative privileges for execution 

    Zoom application installed 

Script Breakdown 

1. Add-Type Definition 

powershell 

Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices; 
 
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)] 
public struct DEVMODE { 
    // Field definitions... 
} 
 
public static class DisplaySettings { 
    // DllImports and methods... 
} 
"@ 
 

Purpose: This section defines a .NET type using C# code embedded within the PowerShell script. It includes the DEVMODE struct and DisplaySettings class to interact with Windows API for display settings manipulation. 

Functions: 

    DEVMODE: Represents display device settings. 

    DisplaySettings: Contains methods to get current display settings, set a new resolution, and restore the original resolution using platform invocation (P/Invoke) to call functions from the user32.dll. 

2. Variable Definitions 

powershell 

$zoomProcessName = "Zoom.exe" 
$zoomResolutionWidth = 1920 
$zoomResolutionHeight = 1080 
 

Purpose: Sets the basic parameters for the script, including the name of the Zoom process and the desired resolution settings when Zoom is active. 

Functions: 

    zoomProcessName: Identifier for the Zoom process used in process monitoring. 

    zoomResolutionWidth and zoomResolutionHeight: Define the screen resolution to be applied when Zoom is running. 

3. Getting Original Settings 

powershell 

$originalSettings = [DisplaySettings]::GetCurrentSettings() 
 

Purpose: Retrieves and stores the current screen resolution settings before any changes are made, ensuring they can be restored later. 

Function: 

    Calls GetCurrentSettings() to fetch and store the current resolution settings in originalSettings. 

4. Main Execution Loop 

powershell 

while ($true) { 
    $zoomRunning = Get-Process -Name $zoomProcessName -ErrorAction SilentlyContinue 
    if ($zoomRunning) { 
        [DisplaySettings]::SetResolution($zoomResolutionWidth, $zoomResolutionHeight) 
        $zoomRunning.WaitForExit() 
        [DisplaySettings]::RestoreResolution($originalSettings) 
    } 
    Start-Sleep -Seconds 10 
} 
 

Purpose: Continuously checks if the Zoom application is running and adjusts the screen resolution accordingly. Once Zoom closes, it restores the original settings. 

Functions: 

    Get-Process: Checks for the Zoom process. 

    SetResolution: Changes the screen resolution when Zoom is detected. 

    WaitForExit: Waits for the Zoom process to terminate before restoring the resolution. 

    RestoreResolution: Restores the screen to its original settings post-Zoom session. 

    Start-Sleep: Pauses the loop to prevent it from consuming too many resources. 

 
