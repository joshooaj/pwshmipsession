# List existing storage configurations
$recorder = Get-VmsRecordingServer | Out-GridView -OutputMode Single
$recorder | Get-VmsStorage

# Check for archive stages on a storage configuration

$storage = $recorder | Get-VmsStorage | Select-Object -First 1
$storage | Get-VmsArchiveStorage


# Add a new storage configuration
$splat = @{
     Name = 'Storage Example'
     Path = 'C:\MediaDatabase'
     Retention = New-TimeSpan -Days 7
     MaximumSizeMB = 100GB / 1MB
     EnableSigning = $true
}
$storage = $recorder | Add-VmsStorage @splat

# Add an archive stage
$splat = @{
    Name          = 'Archive Example'
    Path          = 'C:\MediaDatabase'
    Retention     = (New-TimeSpan -Days 30)
    MaximumSizeMB = 1TB / 1MB
}
$archive = $storage | Add-VmsArchiveStorage @splat
$archive

# We can move hardware between storage too
$hardware = $recorder | Get-VmsHardware | Out-GridView -OutputMode Multiple
$hardware | Get-VmsCamera | Set-VmsDeviceStorage -Destination $storage.Name -PassThru
