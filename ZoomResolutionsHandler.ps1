Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public struct DEVMODE {
    public const int CCHDEVICENAME = 32;
    public const int CCHFORMNAME = 32;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHDEVICENAME)]
    public string dmDeviceName;
    public short dmSpecVersion;
    public short dmDriverVersion;
    public short dmSize;
    public short dmDriverExtra;
    public int dmFields;
    public int dmPositionX;
    public int dmPositionY;
    public int dmDisplayOrientation;
    public int dmDisplayFixedOutput;
    public short dmColor;
    public short dmDuplex;
    public short dmYResolution;
    public short dmTTOption;
    public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHFORMNAME)]
    public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel;
    public int dmPelsWidth;
    public int dmPelsHeight;
    public int dmDisplayFlags;
    public int dmDisplayFrequency;
    public int dmICMMethod;
    public int dmICMIntent;
    public int dmMediaType;
    public int dmDitherType;
    public int dmReserved1;
    public int dmReserved2;
    public int dmPanningWidth;
    public int dmPanningHeight;
}

public static class DisplaySettings {
    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int CDS_UPDATEREGISTRY = 0x01;
    public const int DISP_CHANGE_SUCCESSFUL = 0;

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    public static DEVMODE GetCurrentSettings() {
        DEVMODE currentMode = new DEVMODE();
        currentMode.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        if (!EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref currentMode)) {
            throw new InvalidOperationException("Failed to get current display settings.");
        }
        return currentMode;
    }

    public static bool SetResolution(int width, int height) {
        DEVMODE vDevMode = GetCurrentSettings();
        vDevMode.dmPelsWidth = width;
        vDevMode.dmPelsHeight = height;
        int result = ChangeDisplaySettings(ref vDevMode, CDS_UPDATEREGISTRY);
        return result == DISP_CHANGE_SUCCESSFUL;
    }

    public static bool RestoreResolution(DEVMODE originalMode) {
        int result = ChangeDisplaySettings(ref originalMode, CDS_UPDATEREGISTRY);
        return result == DISP_CHANGE_SUCCESSFUL;
    }
}
"@

$logPath = "C:\Users\Doc\Desktop\ZoomResolutionsLog.txt"

"Starting script..." | Out-File -FilePath $logPath -Append

$zoomProcessName = "Zoom.exe"
$zoomResolutionWidth = 1920
$zoomResolutionHeight = 1080

$originalSettings = [DisplaySettings]::GetCurrentSettings()
"Original settings loaded: Width=$($originalSettings.dmPelsWidth), Height=$($originalSettings.dmPelsHeight)" | Out-File -FilePath $logPath -Append

while ($true) {
    $zoomRunning = Get-Process -Name $zoomProcessName -ErrorAction SilentlyContinue
    if ($zoomRunning) {
        "Zoom is running. Setting resolution to $zoomResolutionWidth x $zoomResolutionHeight" | Out-File -FilePath $logPath -Append
        [DisplaySettings]::SetResolution($zoomResolutionWidth, $zoomResolutionHeight)
        "Resolution set. Waiting for Zoom to close..." | Out-File -FilePath $logPath -Append

        $zoomRunning.WaitForExit()

        "Zoom closed. Restoring original resolution." | Out-File -FilePath $logPath -Append
        [DisplaySettings]::RestoreResolution($originalSettings)
        "Resolution restored." | Out-File -FilePath $logPath -Append
    }
    Start-Sleep -Seconds 10
}

