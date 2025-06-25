[CmdletBinding()]
param (
    # Specifies the Id of the camera you wish to view. Omit this parameter and you can select a camera from an item selection dialog.
    [Parameter(ValueFromPipelineByPropertyName)]
    [guid[]]
    $Id,

    # Specifies the diagnostic overview level to show overlayed onto the image
    [Parameter()]
    [ValidateSet('0','1','2','3','4')]
    [string]
    $DiagnosticLevel = '0'
)

begin {
    Add-Type -AssemblyName PresentationFramework
    if ($null -eq (Get-VmsManagementServer -ErrorAction Ignore)) {
        Connect-ManagementServer -ShowDialog -ErrorAction Stop
    }

    $ids = [collections.generic.list[string]]::new()
}

process {
    $ids.Add($Id)
}

end {
    if ($null -eq $ids -or $ids.Count -eq 0) {
        $cameraItems = Select-Camera -Title "Select one or more cameras" -OutputAsItem  -AllowFolders -AllowServers -RemoveDuplicates
    }
    else {
        $cameraItems = $ids | Foreach-Object { Get-VmsCamera -Id $_ | Get-VmsVideoOSItem -Kind Camera }
    }
    if ($null -eq $cameraItems -or $cameraItems.Count -eq 0) {
        Write-Error "No camera(s) selected"
        return
    }



    $xaml = [xml]@"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
xmlns:local="clr-namespace:WpfApp1"
xmlns:mip="clr-namespace:VideoOS.Platform.Client;assembly=VideoOS.Platform"
Title="$($MyInvocation.Line)" Height="450" Width="800">
<TabControl Name="Tabs">
    <TabItem Header="Live" Name="LiveTab">
        <TabItem.Content>
            <UniformGrid Grid.Row="0" Name="LiveGrid" />
        </TabItem.Content>
    </TabItem>
    <TabItem Header="Playback" Name="PlaybackTab">
        <TabItem.Content>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="100"/>
                </Grid.RowDefinitions>
                <UniformGrid Grid.Row="0" Name="PlaybackGrid" />
                <mip:PlaybackWpfUserControl Name="PlaybackControl" Grid.Row="1" ShowTallUserControl="True" ShowSpeedControl="True" ShowTimeSpanControl="True"/>
            </Grid>
        </TabItem.Content>
    </TabItem>
</TabControl>
</Window>

"@
    try {
        $reader = [system.xml.xmlnodereader]::new($xaml)
        $window = [windows.markup.xamlreader]::Load($reader)
        
        
        $tabs = [system.windows.controls.tabcontrol]$window.FindName('Tabs')
        $liveGrid = [system.windows.controls.primitives.uniformgrid]$window.FindName('LiveGrid')
        $playbackGrid = [system.windows.controls.primitives.uniformgrid]$window.FindName('PlaybackGrid')
        $playbackFqid = [VideoOS.Platform.ClientControl]::Instance.GeneratePlaybackController()
        $playbackControl = [videoos.platform.client.PlaybackWpfUserControl]$window.FindName('PlaybackControl')
        $playbackControl.Init($playbackFqid)
        
        $tabs.Add_SelectionChanged({
            param($source, [system.windows.controls.selectionchangedeventargs]$e)
            if ($e.AddedItems.Count -eq 0 -or $e.RemovedItems.Count -eq 0) {
                # During startup, this event will be triggered by adding the live/playback tabitems to the tabcontrol.
                return
            }

            # When user switches from live to playback and back, we disconnect the live/playback view items to minimize bandwidth/resource usage
            $selected = [system.windows.controls.tabitem]$e.AddedItems[0]
            $deselected = [system.windows.controls.tabitem]$e.RemovedItems[0]
            foreach ($viewer in $selected.FindName("$($selected.Header)Grid").Children) {
                $viewer.Connect()
            }
            foreach ($viewer in $deselected.FindName("$($deselected.Header)Grid").Children) {
                $viewer.Disconnect()
            }
        })

        foreach ($item in $cameraItems) {
            $liveViewer = [videoos.platform.client.imageviewerwpfcontrol]::new()
            $liveViewer.CameraFQID = $item.FQID
            $liveViewer.Initialize()
            $liveViewer.EnableDigitalZoom = $true
            $liveViewer.EnableMouseControlledPtz = $true
            $liveViewer.AdaptiveStreaming = $true
            $liveViewer.Connect()

            $playbackViewer = [videoos.platform.client.imageviewerwpfcontrol]::new()
            $playbackViewer.PlaybackControllerFQID = $playbackFqid
            $playbackViewer.CameraFQID = $item.FQID
            $playbackViewer.Initialize()
            $playbackViewer.EnableDigitalZoom = $true
            $playbackViewer.EnableMouseControlledPtz = $true
            $playbackViewer.EnableBrowseMode = $true

            $liveGrid.AddChild($liveViewer)
            $playbackGrid.AddChild($playbackViewer)

        }
        
        [videoos.platform.environmentmanager]::Instance.EnvironmentOptions.PlayerDiagnosticLevel = $DiagnosticLevel
        [videoos.platform.environmentmanager]::Instance.FireEnvironmentOptionsChangedEvent()
        [videoos.platform.environmentmanager]::Instance.SendMessage([videoos.platform.messaging.message]::new([videoos.platform.messaging.messageid+system]::ModeChangeCommand, [videoos.platform.Mode]::ClientPlayback), $playbackFqid)
        $null = $window.ShowDialog()
    }
    finally {
        foreach ($child in $liveGrid.Children + $playbackGrid.Children) {
            $child.Disconnect()
            $child.Dispose()
        }
        if ($null -ne $playbackControl) {
            $playbackControl.Close()
        }
    }
}