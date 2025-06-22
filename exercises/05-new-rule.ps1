
<# Create a "Record Always" rule applied to all cameras

   Rules are one of the more complex areas of the configuration api. If you
   need to create rules programmatically, I recommend creating them by hand in
   management client first, then inspecting the properties in PowerShell.
#>

New-VmsRule -Name 'Record Always' -Properties @{
    StartRuleType                    = 'TimeInterval'
    StopRuleType                     = 'TimeInterval'
    Always                           = 'True'
    StartActions                     = 'StartRecording'
    StopActions                      = 'StopRecording'
    # This is the default "All cameras" group config item path
    'Start.StartRecording.DeviceIds' = 'CameraGroup[0e1b0ad3-f67c-4d5f-b792-4bd6c3cf52f8]'
}

# Inspect the new rule and all of the properties/values
$rule = Get-VmsRule -Name 'Record Always'
$rule.Properties
