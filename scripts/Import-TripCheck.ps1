#requires -Modules @{ ModuleName="MilestonePSTools"; ModuleVersion="25.2.6" }

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [VideoOS.Platform.ConfigurationItems.RecordingServer]
    $Recorder,

    [Parameter(Mandatory)]
    [string]
    $ApiKey,

    [Parameter()]
    [string]
    $CameraGroupBasePath = "/TripCheck/",

    [Parameter()]
    [ValidateSet(1, 16, 64, 512)]
    [int]
    $CameraCount = 512
)

begin {
    $drivers = @{
        1   = 421
        16  = 409
        64  = 410
        512 = 411
    }
}

process {
    if (!$CameraGroupBasePath.EndsWith("/")) {
        $CameraGroupBasePath = $CameraGroupBasePath + "/"
    }

    $response = Invoke-RestMethod -Method Get -Uri https://api.odot.state.or.us/tripcheck/Cctv/Inventory -UseBasicParsing -Headers @{'Ocp-Apim-Subscription-Key' = $ApiKey }
    $response.CCTVInventoryRequest | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace($_.'last-update-time')) {
            if ($null -eq ($_ | Get-Member -Name 'last-update-time' -ErrorAction SilentlyContinue)) {
                $_ | Add-Member -MemberType NoteProperty -Name 'last-update-time' -Value ([datetime]::MinValue)
            } else {
                $_.'last-update-time' = [datetime]::MinValue
            }
        } else {
            $_.'last-update-time' = [datetime]::Parse($_.'last-update-time')
        }
    }
    $cctvCameras = $response.CCTVInventoryRequest | Sort-Object 'last-update-time' -Descending
        
    # Enable hardware, set name, and enable HTTPS
    $addHardwareParams = @{
        HardwareAddress = 'http://www.tripcheck.com'
        Credential      = [pscredential]::new('a', ('a' | ConvertTo-SecureString -AsPlainText -Force))
        DriverNumber    = $drivers[$CameraCount]
        SkipConfig      = $true
    }
    $hardware = $Recorder | Add-VmsHardware @addHardwareParams

    $hardware | Set-VmsHardware -Name 'TripCheck' -Enabled $true
    $hardware | Set-VmsHardwareGeneralSetting -Settings @{ HTTPSEnabled = 'Yes' }

    # Configure camera channels
    $cameras = $hardware | Get-VmsCamera -EnableFilter All
    for ($index = 0; $index -lt $cctvCameras.Count; $index++) {
        if ($index -ge $CameraCount) {
            Write-Verbose "Universal Driver with $CameraCount channels is now full - the remaining ODOT cameras will not be added"
            break
        }
        $cctvCamera = $cctvCameras[$index]
        $camera = $cameras[$index]
        
        # Enable camera and set name/coordinates/description
        $cameraParams = @{
            Name        = $cctvCamera.'cctv-other'
            ShortName   = $cctvCamera.'device-id'
            Description = "$($cctvCamera.'route-id') milepoint $($cctvCamera.milepoint)"
            Coordinates = "$($cctvCamera.latitude), $($cctvCamera.longitude)"
            Enabled     = $true
        }
        $camera | Set-VmsCamera @cameraParams
            
        # Update general settings for "snapshot" retrieval mode
        $camera | Set-VmsCameraGeneralSetting -Settings @{
            DeliveryMode  = 'Non Multipart Stream'
            KeepAliveType = 'NEVER'
            RetrievalMode = 'Snapshot'
        }

        # Set codec, stream uri, and fps
        $camera | Set-VmsDeviceStreamSetting -StreamName 'Video stream 1' -Settings @{
            Codec         = 'jpeg'
            FPS           = '0.1'
            StreamingMode = 'HTTP'
            ConnectionURI = ([uri]$cctvCamera.'cctv-url').PathAndQuery.TrimStart(@('/'))
        }

        # Add camera to a camera group based on the value of route-id
        $cameraGroupPath = $CameraGroupBasePath + $cctvCamera.'route-id'
        New-VmsDeviceGroup -Path $cameraGroupPath | Add-VmsDeviceGroupMember -Device $camera
    }
}
