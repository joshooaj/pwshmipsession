# Get a recording server
$recorder = Get-VmsRecordingServer | Select-Object -First 1

# For more flexibility, you could prompt the user to pick one too
$recorder = Get-VmsRecordingServer | Out-GridView -OutputMode Single
$credential = Get-Credential -Message "Enter anything"
$recorder | Add-VmsHardware -HardwareAddress http://127.0.0.1:5555 -Name 'Test Camera' -DriverNumber 5000 -Credential $credential

# That line was a little long. Let's introduce "splatting"...

$myParams = @{
    RecordingServer = $recorder
    HardwareAddress = 'http://127.0.0.1:5556'
    Name            = 'Test Camera 2'
    DriverNumber    = 5000
    Credential      = $credential
}
Add-VmsHardware @myParams

# But we don't really want to have to type out all the Add-VmsHardware commands
# so let's run a script instead...

# First, let's get rid of the stablefps cameras we already added...
Get-VmsHardware | Where-Object Model -match 'StableFPS' | Remove-VmsHardware

# Now, let's add and configure two new StableFPS cameras with H.264 (default)
.\scripts\Add-StableFPSHardware.ps1 -Count 2

# And two more with H.265
.\scripts\Add-StableFPSHardware.ps1 -Count 2 -StartingPort 10001 -CameraGroup /StableFPS/H265 -Settings @{
    VideoCodec = 'H265'
    FPS        = 30
}

# Let's export all the StableFPS hardware
$hardware = Get-VmsHardware | Where-Object Model -match 'StableFPS'
$hardware | Export-VmsHardware -Path hardware.csv
$hardware | Export-VmsHardware -Path hardware.xlsx

# And now let's remove and re-import that hardware from the CSV file
Get-VmsHardware | Where-Object Model -match 'StableFPS' | Remove-VmsHardware -Confirm:$false
Import-VmsHardware hardware.csv

# CSV export/import can't capture detailed configuration like general settings
# but the Excel format can!
Get-VmsHardware | Where-Object Model -match 'StableFPS' | Remove-VmsHardware -Confirm:$false
Import-VmsHardware hardware.xlsx


# TripCheck API Demo
# Register for an API key at https://apiportal.odot.state.or.us/product#product=tripcheck-api-data
# to try for yourself - I don't know whether you can get instant access to create an API key today.

$recorder = Get-VmsRecordingServer | Out-GridView -OutputMode Single
$recorder | .\scripts\Import-TripCheck.ps1 -ApiKey (Get-Secret tripcheck -AsPlainText) -CameraCount 16
