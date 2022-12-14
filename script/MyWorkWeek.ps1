#Requires -RunAsAdministrator

<#
    .TAGS
    @task @scheduler @workweek
#>
function Register-MyWorkWeek {
    [CmdletBinding(DefaultParameterSetName = 'Register')]
    Param(
        [ArgumentCompleter({
            $date = Get-Date
            0..62 | foreach {
                Get-Date ($date.AddDays($_)) -Format 'yyyy_MM_dd'
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

    $params = [PsCustomObject]@{
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
