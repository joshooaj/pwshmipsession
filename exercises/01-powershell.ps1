
#region Basic syntax

## Commands (aka cmdlets) are almost always written as "Verb dash Noun"
Get-Process

## Parameter names are specified with a dash and can be positional or named
& notepad
$notepads = Get-Process notepad
Stop-Process -Id $notepads.Id

## Variables are prefixed with a dollar sign
$string = 'Hello, Las Vegas!'
$number = 5

## Everything is an object
$string.Length
$number.GetType()

## PowerShell is a .NET REPL (read-evaluate-print-loop, like python)

[system.environment]::CurrentDirectory

## And there's an implicit "using" statement for the System namespace

[environment]::OSVersion
[AppDomain]::CurrentDomain.GetAssemblies()

#endregion


#region The three most-important commands

Get-Help

Get-Command

Get-Member

## Examples

Get-Help Get-Service
Get-Help Get-Service -Full
Get-Help Get-Service -Parameter Exclude

Get-Command Get-Service
Get-Command -Module MilestonePSTools
Get-Command -Noun *Hardware*
Get-Command -Module MilestonePSTools -Noun *Alarm*

$process = Get-Process | Get-Random
$process
$process | Get-Member
$process.Threads

#endregion


#region Formatting output

## PowerShell has default formatting for objects that aren't captured in a variable
## You can change how data is displayed with Format-* cmdlets
$process | Format-Table
$process | Format-List
# Some objects don't show everything by default so we can add * to override the default list view
$process | Format-List *
$process.Threads | Format-Wide -Column 10
$process.Threads | Format-Table

#endregion


#region Tab and List completion

## Press TAB or CTRL+SPACE after a partial command name
Get-Pro

## Or after the - when writing parameter names
Get-Process -

#endregion


#region Working with data

# Export select properties of all processes to a CSV file
Get-Process | Select-Object Name, Id, StartTime, Path | Export-Csv processes.csv

# Import the CSV file and display it in a grid view
$rows = Import-Csv processes.csv
$rows | Out-GridView

# Unfortunately StartTime and Id are strings instead of a DateTime/Int
$rows | Get-Member

# We can export to JSON as well
Get-Process | Select-Object Name, Id, StartTime, Path | ConvertTo-Json | Set-Content processes.json

# And when we import the data, the DateTime type is preserved
$processes = Get-Content processes.json | ConvertFrom-Json
$processes | Get-Member

# You can also import and export any data in PowerShell using Excel
Install-Module ImportExcel -Scope CurrentUser

$processes | Export-Excel processes.xlsx -TableName processes -TableStyle Medium2 -AutoSize -Show

# When we import the data, the types are (mostly) preserved (Id is now a double)
$processes = Import-Excel processes.xlsx
$processes | Get-Member

#endregion


#region Filtering, sorting, iterating, and grouping

$processes = Get-Process
$processes | Where-Object Id -gt 50000
$processes | Where-Object { $_.Id % 3 -eq 0 }
$processes | Where-Object Name -match 'server$'
$processes | Where-Object Name -like '*dell*'
$processes | Where-Object Name -like '*dell*' | Sort-Object Name -Descending

$processes | ForEach-Object {
    Write-Host "Process: $($_.Name) (Id: $($_.Id))"
}

foreach ($process in $processes) {
    $color = 'Green'
    if ($process.Id -gt 50000) {
        $color = 'Yellow'
    }
    Write-Host "Process: $($process.Name) (Id: $($process.Id))" -ForegroundColor $color
}

$processes | Group-Object Name | Where-Object Count -gt 1 | Sort-Object Count


# Automatic member enumeration
$processes.Id

#endregion


#region Cleanup

Get-ChildItem | ? Extension -in @('.csv', '.json', '.xlsx') | Remove-Item

#endregion
