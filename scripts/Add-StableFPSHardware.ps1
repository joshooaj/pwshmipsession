#requires -Modules @{ ModuleName="MilestonePSTools"; ModuleVersion="25.2.6" }

<#

.SYNOPSIS
Add StableFPS hardware to one or more recording servers.

.DESCRIPTION
This function adds StableFPS hardware to one or more recording servers. If no recording server is specified, it will
add `Count` StableFPS hardware to each recording server found on the VMS.

If no parameters are provided, the default behavior is to add one stable FPS channel using the address
"http://localhost:5000" to each recording server found on the VMS. The codec is set to "H264", the framerate is set
to 5 FPS, and a random video file for the H264 codec is used. All camera channels are enabled and added to a camera
group named "StableFPS".

.PARAMETER RecordingServer
Specifies one or more recording servers. Use Get-VmsRecordingServer to retrieve a list of recording servers. By
default, all recording servers found on the VMS will be used.

.PARAMETER Count
Specifies how many StableFPS hardware items to add to each recording server. The default is 1.

.PARAMETER StartingPort
Specifies the starting port for the StableFPS hardware. The default is 5000. The StableFPS hardware will be added
using an address like "http://localhost:5000", "http://localhost:5001", etc.

.PARAMETER Settings
Specifies a hashtable of general settings to apply to the StableFPS hardware. The available keys and allowed
values can be found by running the Get-VmsHardwareGeneralSetting command with the -ValueTypeInfo parameter
against and existing StableFPS hardware item.

.PARAMETER CameraGroup
Specifies the path of the camera group to add the cameras to. The default is "/StableFPS". If the group does not
exist, it will be created.

.PARAMETER DisableMotion
Specifies that motion detection should be disabled for the cameras. By default, motion detection is enabled.

.PARAMETER DisableRecording
Specifies that recording should be disabled for the cameras. By default, recording is enabled.

.EXAMPLE
.\Add-StableFPSHardware.ps1

Without any parameters, this will add one StableFPS hardware item to each recording server found on the VMS, and
each will be configured to stream video using H.264 at 5 FPS.

.EXAMPLE
$recorders = Get-VmsRecordingServer | Out-GridView -OutputMode Multiple -Title 'Select Recording Servers'
.\Add-StableFPSHardware.ps1 -RecordingServer $recorders -StartingPort 2222 -Count 100 -DisableMotion -DisableRecording

This will prompt for a recording server selection. Select one or more recording servers. On each selected recording
server, 100 StableFPS hardware will be added. Motion detection and recording will be disabled for all cameras.

.EXAMPLE
.\Add-StableFPSHardware.ps1 -Count 10 -StartingPort 10001 -CameraGroup /StableFPS/H265 -Settings @{
    VideoCodec = 'H265'
    FPS        = 30
}

This adds 10 StableFPS hardware items to each recording server starting at port 10001. Cameras will use H.265 and
stream at 30 FPS. Cameras will be added to a camera group named "H265" under the "StableFPS" parent group.

.EXAMPLE
$settings = @{
    FPS                      = '5'
    VideoCodec               = 'JPEG'
    SyncFirstStream          = 'Yes'
    VideoJPEGFiles           = '1024x768_HumanStickFigure'
    EdgeVideoCodec           = 'JPEG'
    EdgeVideoJPEGFiles       = '640x480_rotating_bar'
    AudioEncoding            = 'G711'
    AudioG711Files           = 'beep_1000Hz'
    MetadataBoundingBoxFiles = 'HumanStickFigure'
}
$newHardware = .\Add-StableFPSHardware.ps1 -Count 5 -StartingPort 6000 -Settings $settings
$metadata = $newHardware | Get-VmsMetadata -EnableFilter All | Set-VmsMetadata -Enabled $true -PassThru
New-VmsDeviceGroup -Type Metadata -Name StableFPS | Add-VmsDeviceGroupMember -Device $metadata
$newHardware | Get-VmsMicrophone -EnableFilter All | Set-VmsMicrophone -Enabled $true
New-VmsDeviceGroup -Type Microphone -Name StableFPS | Add-VmsDeviceGroupMember -Device $mics

This will add 5 StableFPS hardware to each recording server, and configure them all to use the
"HumanStickFigure" video with the corresponding metadata. It will also enable the microphones and
configure them to use the 1000Hz beep tone. Microphone and metadata devices will be added to a new
device group named "StableFPS".

.NOTES
Visit https://www.milestonepstools.com for full MilestonePSTools module documentation.

.LINK
https://www.milestonepstools.com/commands/en-US/

#>
[CmdletBinding()]
param(
    [Parameter()]
    [ArgumentCompleter([MilestonePSTools.Utility.MipItemNameCompleter[VideoOS.Platform.ConfigurationItems.RecordingServer]])]
    [MilestonePSTools.Utility.MipItemTransformation([VideoOS.Platform.ConfigurationItems.RecordingServer])]
    [VideoOS.Platform.ConfigurationItems.RecordingServer[]]
    $RecordingServer,

    [Parameter()]
    [ValidateRange(1, [int]::MaxValue)]
    [string]
    $Count = 1,

    [Parameter()]
    [ValidateRange(1, 65535)]
    [int]
    $StartingPort = 5000,

    [Parameter()]
    [hashtable]
    $Settings = @{
        FPS            = 5
        VideoCodec     = 'H264'
        EdgeVideoCodec = 'H264'
    },

    [Parameter()]
    [string]
    $CameraGroup = '/StableFPS',

    [Parameter()]
    [switch]
    $DisableMotion,

    [Parameter()]
    [switch]
    $DisableRecording
)

if (-not $MyInvocation.BoundParameters.ContainsKey('RecordingServer')) {
    $RecordingServer = Get-VmsRecordingServer
}

$cred = [pscredential]::new('a', ('a' | ConvertTo-SecureString -AsPlainText -Force))

$deviceGroup = New-VmsDeviceGroup -Path $CameraGroup
foreach ($recorder in $RecordingServer) {
    for ($port = $StartingPort; $port -lt $StartingPort + $Count; $port++) {
        $hwParams = @{
            Name            = "StableFPS ($($recorder.Name)`:$port)"
            HardwareAddress = "http://localhost:$port"
            DriverNumber    = 5000
            Credential      = $cred
            Force           = $true
            ErrorAction     = 'Stop'
        }
        $hw = $recorder | Add-VmsHardware @hwParams
        $valueTypeInfo = $hw | Get-VmsHardwareGeneralSetting -ValueTypeInfo

        if ($Settings.VideoCodec -notin @('H264', 'H265', 'JPEG')) {
            $Settings.VideoCodec = 'H264'
        }
        if ($null -eq ($Settings.Keys | Where-Object { $_ -match "Video$($Settings.VideoCodec)Files" })) {
            # Use a random video file      
            $videoFileKeys = $valueTypeInfo.Keys | Where-Object { $_ -match "Video$($Settings.VideoCodec)Files" }
            $videoFile = ($valueTypeInfo["Video$($Settings.VideoCodec)Files"] | Where-Object Value -ne 'None').Value | Get-Random
            foreach ($key in $videoFileKeys) {
                $Settings[$key] = $videoFile
            }
        }
        
        $hw | Set-VmsHardwareGeneralSetting -Settings $Settings

        $cameras = $hw | Get-VmsCamera -EnableFilter All | Set-VmsCamera -Enabled $true -RecordingEnabled (!($DisableRecording.ToBool())) -PassThru
        $cameras | Set-VmsCameraMotion -Enabled (!($DisableMotion.ToBool()))
        $deviceGroup | Add-VmsDeviceGroupMember -Device $cameras
        $hw
    }
}
