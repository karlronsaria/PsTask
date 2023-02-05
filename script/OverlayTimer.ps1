#Requires -Module PsClock

function Start-OverlayTimer {
    Param(
        [String]
        $Seconds,

        [String]
        $Command
    )

    $ErrorActionPreference = 'Stop'
    Import-Module -Name 'PsClock'
    $width = 200
    $height = 100

    # link
    # - url: https://stackoverflow.com/questions/7967699/get-screen-resolution-using-wmi-powershell-in-windows-7
    # - retrieved: 2023_02_03
    Add-Type -AssemblyName System.Windows.Forms
    $size = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize

    Start-PsCountdownTimer `
        -Seconds $Seconds `
        -OnTop `
        -Position ($size.Width - $width), ($size.Height - $height)

    do {
        Start-Sleep -Seconds 1
    }
    while ($PsCountdownClock.Running)

    Invoke-Expression $Command
}

