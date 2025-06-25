# MilestonePSTools includes a VERY detailed "camera report" command with ~80 properties

Get-VmsCameraReport | Out-GridView

# There are optional properties like retention info and percentage of time video has been recorded
Get-VmsCameraReport -IncludeRetentionInfo -IncludeRecordingStats | Out-GridView

# The camera report can take a long time to run, so if you only need very specific information you
# can get that directly using different commands in the module, or even the MIP SDK classes directly.


# Get-ItemState calls ProvideCurrentStateRequest for you using MessageCommunicationManager
# https://doc.developer.milestonesys.com/html/index.html?base=miphelp/class_video_o_s_1_1_platform_1_1_messaging_1_1_message_communication.html

Get-ItemState
Get-ItemState -CamerasOnly


# We can get more detailed device status using RecorderCommandService
$recorder = Get-VmsRecordingServer | Select-Object -First 1
$client = $recorder | Get-RecorderStatusService2
$response = $client.GetCurrentDeviceStatus((Get-VmsToken), ($recorder | get-vmshardware | get-vmscamera).Id)
$response.CameraDeviceStatusArray

# We can get current live/recorded stream statistics like FPS, bitrate and resolution
$response = $client.GetVideoDeviceStatistics((Get-VmsToken), ($recorder | get-vmshardware | get-vmscamera).Id)
$response[0].VideoStreamStatisticsArray

# We can also ask for storage status
$client.GetRecordingStorageStatus((Get-VmsToken))
