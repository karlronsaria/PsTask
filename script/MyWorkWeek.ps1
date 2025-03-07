#Requires -RunAsAdministrator

<#
    .TAGS
    @task @scheduler @workweek
#>
function Register-MyWorkWeek {
    [Alias('WorkWeek')]
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

        [Parameter(ParameterSetName = 'NoRegister')]
        [Switch]
        $NoRegister
    )

    . $PsScriptRoot\..\script\MyPsTask.ps1

    $myWorkWeek =
        cat "$PsScriptRoot\..\res\myworkweek.json" `
            | ConvertFrom-Json

    $params = @{
        StartDate = $StartDate
        SaveToFile = $SaveToFile
        TimerMinutes = $myWorkWeek.TimerMinutes
        DriveTimeMinutes = $myWorkWeek.DriveTimeMinutes
        NoRegister = $NoRegister
    }

    if (-not $NoRegister) {
        $params | Add-Member `
            -MemberType 'NoteProperty' `
            -Name 'Force' `
            -Value $true
    }

    return Register-WorkWeekShutdownScheduledTask @params
}
