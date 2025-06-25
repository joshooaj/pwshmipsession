# Peter brought up the Control.DriverCommand feature of driver integrations
# So I thought I would show it in action using an example function written a few months ago
# https://gist.github.com/joshooaj/af734c840547f19267adeba26dfe57e6
# https://youtu.be/pi6Gv2KAVV8

# First, my example function is defined in ./scripts/Send-VmsDriverCommand.ps1
# and I need to dot-source it to make the function available in this PowerShell session
. .\scripts\Send-VmsDriverCommand.ps1

# Next I'll just search for a camera with "Axis" in the name and grab the first one
$camera = Get-VmsCamera -Name Axis | Select-Object -First 1

# Finally, I'll pipe the camera to my custom function
# and provide a path to a known endpoint on the camera
$camera | Send-VmsDriverCommand -Path 'axis-cgi/applications/list.cgi'