function Read-TimeString {
    Param(
        [String]
        $Prompt
    )

    $hourPattern = '((0|1)\d|2[0-3])'
    $secondPattern = '([0-5]\d)'
    $success = $false
    $str = ''

    do {
        $success = $true
        $str = Read-Host -Prompt $Prompt

        if ([String]::IsNullOrWhiteSpace($str)) {
            return [PsCustomObject]@{
                Success = $false
                Time = ''
            }
        }

        if ($str -match "^$hourPattern$") {
            $str = "$($str)0000"
        }
        elseif ($str -match "^$($hourPattern)$($secondPattern)$") {
            $str = "$($str)00"
        }
        elseif ($str -notmatch "^$($hourPattern)$($secondPattern){2}$") {
            $success = $false
            Write-Host `
                'Input string not in correct time format: (HH(mm(ss)))'
        }
    }
    while (-not $success)

    return [PsCustomObject]@{
        Success = $true
        Time = $str
    }
}

function Read-WeekSchedule {
    [CmdletBinding(DefaultParameterSetName = 'ByDateTimeObject')]
    Param(
        [Parameter(ParameterSetName = 'ByDateTimeObject')]
        [DateTime]
        $Date,

        [Parameter(ParameterSetName = 'ByString')]
        [String]
        $DateString
    )

    $what = switch ($PsCmdlet.ParameterSetName) {
        'ByString' {
            if ([String]::IsNullOrWhiteSpace($StartDate)) {
                Read-WeekSchedule
                break
            }

            $capture = [Regex]::Match($StartDate, "\d{4}(-\d{2}){2}") # Uses DateTimeFormat

            if (-not $capture.Success) {
                Read-WeekSchedule
                break
            }

            $str = $capture.Value

            Read-WeekSchedule `
                -Date ([DateTime]::ParseExact( `
                    $capture.Value, `
                    'yyyy-MM-dd', ` # Uses DateTimeFormat
                    $null `
                ))
        }

        'ByDateTimeObject' {
            if (-not $Date) {
                $Date = (Get-Date).AddDays(1)
            }

            $times = @()

            foreach ($i in 0..6) {
                $day = $Date.DayOfWeek

                $result = Read-TimeString `
                    -Prompt "$($Date.DayOfWeek) (Enter to skip)"

                if ($result.Success) {
                    $time = "$($Date.ToString('yyyy-MM-dd'))-$($result.Time)" # Uses DateTimeFormat
                    $times = $times + @($time)
                }

                $Date = $Date.AddDays(1)
            }

            return $times
        }
    }

    return $what
}

function Get-WeekDayScheduledTask {
    [CmdletBinding(DefaultParameterSetName = 'ReadScheduleStartingToday')]
    Param(
        [Parameter(ParameterSetName = 'ReadSchedule')]
        [String]
        $StartDate,

        [Parameter(ParameterSetName = 'NoRead')]
        [String[]]
        $StartBoundary,

        [String]
        $TaskName,

        [Int]
        $MinuteHeadStart = 0,

        [String]
        $Command,

        [String[]]
        $Arguments,

        [String]
        $Description
    )

    $now = Get-Date -Format o
    $defaults = cat "$PsScriptRoot\..\res\default.json" | ConvertFrom-Json
    $directory = $defaults.RegistrationInfo.Directory
    $author = "$($env:UserDomain)\$($env:UserName)"
    $myArgs = "$($Arguments -Join ' ')"
    $expiryDays = 14
    $userId =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

    # TODO: remove
    $calendarTrigger =
@"
    <CalendarTrigger>
      <StartBoundary>{MY_START_BOUNDARY}</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
"@

    $timeTrigger =
@"
    <TimeTrigger>
      <StartBoundary>{MY_START_BOUNDARY}</StartBoundary>
      <EndBoundary>{MY_END_BOUNDARY}</EndBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
"@

    $StartBoundary = switch ($PsCmdlet.ParameterSetName) {
        'NoRead' {
            $StartBoundary
        }

        'ReadSchedule' {
            Read-WeekSchedule `
                -DateString $StartDate
        }

        'ReadScheduleStartingToday' {
            Read-WeekSchedule
        }
    }

    $triggers = $StartBoundary `
        | where { -not [String]::IsNullOrWhiteSpace($_) } `
        | foreach {
            $start =
                [DateTime]::ParseExact($_, 'yyyy-MM-dd-HHmmss', $null) ` # Uses DateTimeFormat
                    - (New-TimeSpan -Minutes $MinuteHeadStart)

            $end = $start.AddDays(1)
            $trigger = $timeTrigger

            $trigger = $trigger.Replace( `
                "{MY_START_BOUNDARY}", `
                $start.ToString('o') `
            )

            $trigger = $trigger.Replace( `
                "{MY_END_BOUNDARY}", `
                $end.ToString('o') `
            )

            $trigger
        }

    $triggers = $triggers -Join "`r`n"
    $xml = cat "$PsScriptRoot\..\res\Template_SingleDayTask.xml"
    $xml = $xml.Replace('{NOW}', $now)
    $xml = $xml.Replace('{AUTHOR}', $author)
    $xml = $xml.Replace('{DESCRIPTION}', $Description)
    $xml = $xml.Replace('{DIRECTORY}', $directory)
    $xml = $xml.Replace('{USERID}', $userId)
    $xml = $xml.Replace('{TASK_NAME}', $TaskName)
    $xml = $xml.Replace('{TRIGGERS}', $Triggers)
    $xml = $xml.Replace('{COMMAND}', $Command)
    $xml = $xml.Replace('{ARGUMENTS}', $myArgs)
    $xml = $xml.Replace('{EXPIRY_DAYS}', $expiryDays)
    return $xml
}
