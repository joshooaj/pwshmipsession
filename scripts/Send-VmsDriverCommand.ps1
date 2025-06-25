function Send-VmsDriverCommand {
    <#
    .SYNOPSIS
    Sends a custom HTTP request or command to a device added to an XProtect VMS.
    
    .PARAMETER Camera
    Specifies the camera to which the driver command should be sent.
    
    .PARAMETER Fqid
    Specifies the FQID associated with the destination device. Try `Get-VmsVideoOSItem` to retrieve an item, and then
    use the FQID property on that object.
    
    .PARAMETER Method
    Specifies the HTTP Method to use. The default is "Get" and the options are "Get", "Post", "Put", "Patch", and "Delete".
    
    .PARAMETER Path
    Specifies the relative HTTP path on the device. For example, to send a command to "http://192.168.1.5/axis-cgi/applications/list.cgi",
    provide a Camera or Fqid value for the device at 192.168.1.5, and the value of Path should be "axis-cgi/applications/list.cgi".

    Note: Query string parameters can be included in Path. The underlying MIP SDK expects the query string to be sent
    separately from the path, but this function will take care of that for you.
    
    .PARAMETER Body
    When sending a POST, PUT, or PATCH it's common to provide data in the message body. Use this parameter to supply the
    HTTP message body.
    
    .EXAMPLE
    $camera = Select-Camera -SingleSelect
    $camera | Send-VmsDriverCommand -Path 'axis-cgi/applications/list.cgi'
    # Example OUTPUT
    # <reply result="ok">
    #   <application Name="vmd" NiceName="AXIS Video Motion Detection" Vendor="Axis Communications" Version="4.5-8" ApplicationID="143440" License="None" Status="Stopped" ConfigurationPage="local/vmd/config.html" VendorHomePage="http://www.axis.com" LicenseName="Proprietary" />
    #   <application Name="objectanalytics" ApplicationID="412806" NiceName="AXIS Object Analytics" Vendor="Axis Communications" Version="1.14.35" Status="Stopped" License="None" ConfigurationPage="local/objectanalytics/index.html" VendorHomePage="http://www.axis.com" LicenseName="available" />
    # </reply>

    .NOTES
    Due to the way the MIP SDK handles custom driver commands, you cannot provide query string parameters and a message
    body. The query string and the body share the same underlying `DriverCommandData.Parameter` field.

    #>
    [CmdletBinding(DefaultParameterSetName = 'Camera')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Camera')]
        [VideoOS.Platform.ConfigurationItems.Camera]
        $Camera,
        
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FQID')]
        [VideoOS.Platform.FQID]
        $Fqid,

        [Parameter(Mandatory, ParameterSetName = 'Camera')]
        [Parameter(Mandatory, ParameterSetName = 'FQID')]
        [string]
        $Path,
        
        [Parameter()]
        [string]
        $Body,
        
        [Parameter()]
        [ValidateSet('Get', 'Post', 'Put', 'Patch', 'Delete')]
        [string]
        $Method = 'Get'
    )
    
    process {
        $uriBuilder = [uribuilder]('http://localhost/{0}' -f $Path.TrimStart('/'))
        $data = [VideoOS.Platform.Messaging.DriverCommandData]@{
            Command   = '{0}:{1}' -f $Method.ToUpper(), $uriBuilder.Path
            Parameter = $uriBuilder.Query.TrimStart('?')
        }
        if (![string]::IsNullOrWhiteSpace($Body)) {
            $data.Parameter = $Body
        }
        $messageArgs = @{
            MessageId             = [VideoOS.Platform.Messaging.MessageId+Control]::DriverCommand
            Data                  = $data
            ResponseMessageId     = [VideoOS.Platform.Messaging.MessageId+Control]::DriverResponse
            DestinationEndpoint   = ($Camera | Get-VmsVideoOSItem -Kind Camera).FQID
            UseEnvironmentManager = $true
        }
        $response = Send-MipMessage @messageArgs -ErrorAction Stop
        if (!$response.Data.Success) {
            Write-Error -Message "DriverCommand returned an error: $($response.Data.ErrorText)" -TargetObject $response.Data
            return
        }
        $response.Data.Response
    }
}