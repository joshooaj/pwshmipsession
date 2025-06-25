# Login to your management server

$credential = [pscredential]::new('xprotect', (ConvertTo-SecureString 'Ujt96bYqph9a' -AsPlainText -Force))
Connect-Vms -ServerAddress http://40.125.85.141 -Credential $credential

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

# CTRL + C to stop

Get-VmsLog | Format-Table

Get-Vmslog -LogType Audit | Format-Table