<#
    .TAGS
    @task @scheduler
#>
function Register-WorkWeekShutdownScheduledTask {
    [CmdletBinding(DefaultParameterSetName = 'Register')]
    Param(
        [String]
        $StartDate,

        [Switch]
        $SaveToFile,

        [Int]
        $TimerMinutes = 0,

        [Int]
        $DriveTimeMinutes = 0,

        [Parameter(ParameterSetName = 'Register')]
        [Switch]
        $Force,

        [Parameter(ParameterSetName = 'NoRegister')]
        [Switch]
        $NoRegister
    )

    . $PsScriptRoot\..\script\PsTask.ps1

    $params = @{
        StartDate = $StartDate
        TaskName = 'TimedShutdown_WorkWeek'
        Description = 'Displays an overlay timer and shuts down the computer at a certain time.'
        Command = 'OverlayTimer.exe'
        Arguments = ($TimerMinutes * 60), 'shutdown', '"-f -s -t 0"'
        MinuteHeadStart = $TimerMinutes + $DriveTimeMinutes
    }

    if (-not (Get-Command $params.Command -ErrorAction SilentlyContinue)) {
        return [PsCustomObject]@{
            Success = $false
            Message = "This script requires $($params.Command) to be available on the machine."
        }
    }

    if ($StartDate) {
        $params['StartDate'] = $StartDate
    }

    $xml = Get-WeekDayScheduledTask @params
    $filePath = ''

    if ($SaveToFile) {
        $filePath = "$($params.TaskName)_$(Get-Date -f yyyy_MM_dd_HHmmss).xml"
        $xml | Out-File $filePath
    }

    $defaults = cat "$PsScriptRoot\..\res\default.json" | ConvertFrom-Json
    $directory = $defaults.RegistrationInfo.Directory
    $register = ''

    if ($NoRegister) {
        if (-not $SaveToFile) {
            return [PsCustomObject]@{
                Success = $true
                Xml = $xml
            }
        }
    }
    else {
        if ($Force) {
            Unregister-ScheduledTask `
                -TaskName $params.TaskName `
                -Confirm:$false
        }

        $register = Register-ScheduledTask `
            -TaskName $params.TaskName `
            -TaskPath $directory `
            -Xml ($xml | Out-String)
    }

    return [PsCustomObject]@{
        'Success' = $true
        'FilePath' = $filePath
        'Register-ScheduledTask' = $register
    }
}

function Edit-WorkDayShutdownScheduledTask {
# TODO
}

