# Login to your management server

Connect-Vms

# Explore the VMS and see what is available

# Get a list of "Get" commands
Get-Command -Module MilestonePSTools -Verb Get

Get-VmsManagementServer | Format-List

Get-VmsRecordingServer

Get-VmsHardware

Get-VmsCamera

Get-VmsRole

Get-VmsViewGroup

Get-LoginSettings

Get-Token

Get-UserDefinedEvent

# Try listening for MIP event messages
Trace-Events

Get-VmsLog | Format-Table