#requires -Module MilestonePSTools
<#
.SYNOPSIS
Get the update history for an XProtect VMS alarm by ID

.DESCRIPTION
This function retrieves the update history for a specific alarm on an
XProtect VMS based on the provided alarm ID. The alarm ID is the number
shown in the ID column in XProtect Smart Client.

.PARAMETER Alarm
An AlarmLine object returned by the Get-AlarmLine cmdlet.

.PARAMETER Id
The ID of the alarm to retrieve history for. The alarm ID is displayed in
the ID column for each alarm in XProtect Smart Client.

.EXAMPLE
.\Get-AlarmHistory.ps1 -Id 12345

Retrieves the update history for the alarm with ID 12345.

.EXAMPLE
.\Get-AlarmHistory.ps1 -Id 12345 | Export-Csv -Path alarmhistory.csv -NoTypeInformation

Retrieves the update history for the alarm with ID 12345 and exports it to
a CSV file in the current folder named alarmhistory.csv.

.EXAMPLE
$condition = New-AlarmCondition -Target Timestamp -Operator GreaterThan -Value (Get-Date).AddHours(-1)
Get-AlarmLine -Conditions $condition | .\get-AlarmHistory.ps1 | Export-Csv history.csv -NoTypeInformation

Export the history for all alarms that have been created in the last hour to a
CSV file in the current folder. History for all alarms will be in the same file
and can be differentiated by the number in the Id column.

.EXAMPLE
$condition = New-AlarmCondition -Target Timestamp -Operator GreaterThan -Value (Get-Date).AddHours(-1)
Get-AlarmLine -Conditions $condition | ForEach-Object {
    $_ | .\Get-AlarmHistory.ps1 | Export-Csv "Alarm_$($_.LocalId).csv" -NoTypeInformation
}

Export the history for all alarms that have been created in the last hour to a
CSV file in the current folder with the alarm ID in the filename.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'AlarmLine')]
    [VideoOS.Platform.Proxy.Alarm.AlarmLine]
    $Alarm,

    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Id')]
    [int]
    $Id
)

begin {
    $client = Get-IAlarmClient
}

process {
    if ($null -eq $Alarm) {
        $condition = New-AlarmCondition -Target LocalId -Operator Equals -Value $Id
        $Alarm = Get-AlarmLine -Conditions $condition
    }


    $history = $client.GetAlarmUpdateHistory($Alarm.Id)
    [pscustomobject]@{
        Time   = $Alarm.Timestamp
        Id     = $Alarm.LocalId
        Key    = 'Created'
        Value  = "$($Alarm.Name) (Source: $($Alarm.SourceName))"
        Author = ''
    }
    foreach ($entry in $history | Sort-Object Time) {
        $entry | Select-Object Time, @{Name='Id';Expression={$Alarm.LocalId}}, Key, Value, Author
    }
}

end {
    $client.CloseClient()
}