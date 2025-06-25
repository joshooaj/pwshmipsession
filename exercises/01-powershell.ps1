
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
