#Requires -RunAsAdministrator

<#
    .TAGS
    @task @scheduler
#>
function Register-WorkWeekShutdownScheduledTask {
    [CmdletBinding(DefaultParameterSetName = 'Register')]
    Param(
        [ArgumentCompleter({
            Param($A, $B, $C)

            return (@(0 .. 62) + @(-61 .. -1)) |
                foreach -Begin {
                    $date = Get-Date
                } -Process {
                    Get-Date ($date.AddDays($_)) -Format 'yyyy-MM-dd' # Uses DateTimeFormat
                } |
                where {
                    $_ -like "$C*"
                }
        })]
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

    $defaults = cat "$PsScriptRoot\..\res\default.json" | ConvertFrom-Json

    $params = @{
        StartBoundary = Read-WeekSchedule -DateString $StartDate
        TaskName = 'TimedShutdown_WorkWeek'
        Description = 'Displays an overlay timer and shuts down the computer at a certain time.'
        Command = $defaults.Module.Command
        Arguments = ($TimerMinutes * 60), '"shutdown -f -s -t 0"'
        MinuteHeadStart = $TimerMinutes + $DriveTimeMinutes
    }

    if (-not (Get-Command $params.Command -ErrorAction SilentlyContinue)) {
        return [PsCustomObject]@{
            Success = $false
            Message = "This script requires $($params.Command) to be available on the machine."
        }
    }

    $xml = Get-WeekDayScheduledTask @params
    $filePath = ''

    if ($SaveToFile) {
        $filePath = "$($params.TaskName)_$(Get-Date -f yyyy-MM-dd-HHmmss).xml" # Uses DateTimeFormat
        $xml | Out-File $filePath
    }

    $directory = $defaults.RegistrationInfo.Directory
    $register = ''

    if ($NoRegister) {
        if (-not $SaveToFile) {
            return [PsCustomObject]@{
                Success = $true
                StartBoundary = $params.StartBoundary
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
            -Xml ($xml | Out-String) `
            -Force
    }

    $schedule = $params.StartBoundary `
        | foreach {
            [PsCustomObject]@{
                what = 'Work'
                when = $_
                type = 'todayonly'
            }
        } | ConvertTo-Json | ConvertFrom-Json

    return [PsCustomObject]@{
        'Success' = $true
        'FilePath' = $filePath
        'Register-ScheduledTask' = $register
        'Schedule' = $schedule
        'Xml' = $xml
    }
}

function Edit-WorkDayShutdownScheduledTask {
# TODO
}

