# Get a recording server
$recorder = Get-VmsRecordingServer | Select-Object -First 1

# For more flexibility, you could prompt the user to pick one too
$recorder = Get-VmsRecordingServer | Out-GridView -OutputMode Single
$credential = Get-Credential -Message "Enter anything"
$randomPort = Get-Random -Minimum 1000 -Maximum 65000
$recorder | Add-VmsHardware -HardwareAddress "http://127.0.0.1:$randomPort/" -Name 'Test Camera' -DriverNumber 5000 -Credential $credential

# Let's remove that hardware...

Get-VmsHardware | Where-Object Address -eq "http://127.0.0.1:$randomPort/" | Remove-VmsHardware -Confirm:$false

# That line was a little long. Let's introduce "splatting"...

$myParams = @{
    RecordingServer = $recorder
    HardwareAddress = "http://127.0.0.1:$randomPort/"
    Name            = 'Test Camera 2'
    DriverNumber    = 5000
    Credential      = $credential
}
Add-VmsHardware @myParams

Get-VmsHardware | Where-Object Address -eq "http://127.0.0.1:$randomPort/" | Remove-VmsHardware -Confirm:$false

# But we don't really want to have to type out all the Add-VmsHardware commands
# so let's run a script instead...

# Let's add and configure two new StableFPS cameras with H.264 (default)
$hardware = .\scripts\Add-StableFPSHardware.ps1 -Count 2 -StartingPort $randomPort
$hardware

# And two more with H.265
$hardware += .\scripts\Add-StableFPSHardware.ps1 -Count 2 -StartingPort ($randomPort + 2) -CameraGroup /StableFPS/H265 -Settings @{
    VideoCodec = 'H265'
    FPS        = 30
}
$hardware

# Let's export all the StableFPS hardware
$hardware = Get-VmsHardware | Where-Object Model -match 'StableFPS'
$hardware | Export-VmsHardware -Path hardware.csv
$hardware | Export-VmsHardware -Path hardware.xlsx

# And now let's remove and re-import that hardware from the CSV file
$hardware | Remove-VmsHardware -Confirm:$false
$devices = Import-VmsHardware hardware.csv
$devices

# CSV export/import can't capture detailed configuration like general settings
# but the Excel format can!
$devices | Get-VmsCamera | Get-VmsParentItem | Remove-VmsHardware -Confirm:$false
Import-VmsHardware hardware.xlsx


# TripCheck API Demo
# Register for an API key at https://apiportal.odot.state.or.us/product#product=tripcheck-api-data
# to try for yourself - I don't know whether you can get instant access to create an API key today.

$recorder = Get-VmsRecordingServer | Out-GridView -OutputMode Single
$recorder | .\scripts\Import-TripCheck.ps1 -ApiKey (Get-Secret tripcheck -AsPlainText) -CameraCount 16
