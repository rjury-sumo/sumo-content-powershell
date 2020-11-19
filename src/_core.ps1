<#
    .SYNOPSIS
    Powershell functions to export content from sumologic content and folder apis. https://api.sumologic.com/docs/#tag/contentManagement
 
    .DESCRIPTION
    Powershell wrapper to get, export or import content from Sumo Logic Library.

    .EXAMPLE
    Start the default single session, using SUMO_ACCESS_ID and KEY variables but a custom endpoint
    $s1 = new-ContentSession -endpoint 'https://api.au.sumologic.com' 
    $FolderNameToExport = "test"
    $parent_folder = get-PersonalFolder 
    $export_id = ($parent_folder.children | where {$_.ItemType -eq "Folder" -and $_.name -eq $FolderNameToExport}).id
    $export_item_path = get-ContentPath -id $export_id
    $item_by_path = get-ContentByPath -path $export_item_path
    $export_item =  get-ExportContent -id $export_id
    $export_item |  ConvertTo-Json -Depth 100 | Out-File -FilePath ./temp.json -Encoding ascii -Force -ErrorAction Stop

    .EXAMPLE
    Using two sessions s1 and s2. Provide -sumo_session param to commands to specify instance.
    $s1 =  new-ContentSession -endpoint 'https://api.au.sumologic.com' 
    $s2 =  new-ContentSession -accessid $env:SUMO_ACCESS_ID_BE -accesskey $env:SUMO_ACCESS_KEY_BE  
    $parent_folder = get-PersonalFolder -sumo_session $s1 
    $parent_folder = get-PersonalFolder -sumo_session $s2
    
#>

#if (-not ([System.Management.Automation.PSTypeName]'SumoAPISession').Type) {
try { [SumoAPISession] | Out-Null } catch { Add-Type -TypeDefinition  @"
public class SumoAPISession
{
    public SumoAPISession(string Endpoint, object WebSession, string Name, string isAdminMode) {
        this.Endpoint = Endpoint;
        this.WebSession = WebSession;
        this.Name = Name;
        this.isAdminMode = isAdminMode;
    }
    public string Endpoint;
    public object WebSession;
    public string Name;
    public string isAdminMode;
}
"@ 
}

<#
    .DESCRIPTION
    Create a new sumo session object.

    .PARAMETER endpoint
    API endpoint such as https://api.us2.sumologic.com.
    defaults to: $env:SUMOLOGIC_API_ENDPOINT

    .PARAMETER accessid
    API endpoint such as https://api.us2.sumologic.com
    defaults to: $env:SUMO_ACCESS_ID

    .PARAMETER accesskey
    API endpoint such as https://api.us2.sumologic.com
    defaults to: $env:SUMO_ACCESS_KEY

    .PARAMETER name
    Optional name property. 
    defaults to: accessid

    .EXAMPLE
    $s = new-ContentSession -endpoint https://api.au.sumologic.com

    .EXAMPLE
    $instance1 = new-ContentSession -endpoint https://api.au.sumologic.com -accessid 'xxxxx' -accesskey 'yyyy' -name 'InstanceA'
    $instance2 = new-ContentSession -endpoint https://api.au.sumologic.com -accessid 'aaaa' -accesskey 'bbbb' -name 'InstanceB'

    .OUTPUTS
    SumoAPISession. Contains endpoint, Name, isAdminMode and WebSession properties
#>
function new-ContentSession() {
    Param(
        [parameter(Mandatory = $false)][string] $endpoint = $env:SUMOLOGIC_API_ENDPOINT,
        [parameter(Mandatory = $false)][string] $accessid = $env:SUMO_ACCESS_ID,
        [parameter(Mandatory = $false)][string] $accesskey = $env:SUMO_ACCESS_KEY,
        [parameter(Mandatory = $false)][string] $name = $accessid,
        [parameter(Mandatory = $false)][ValidateSet('true', 'false')][string] $isAdminMode = "false"

    )
    $Credential = New-Object System.Management.Automation.PSCredential $accessid, ($accesskey | ConvertTo-SecureString -AsPlainText -Force )

    # default endpoint
    if ($endpoint -match '^(au|ca|de|eu|fed|jap|in|us2)$') {
        $endpoint = ("https://api.SERVER.sumologic.com" -replace "SERVER", $endpoint)
    }

    if ($endpoint -eq 'prod') {
        $endpoint = "https://api.sumologic.com" 
    }
    
    if ($endpoint) { } else { $endpoint = "https://api.us2.sumologic.com" }
    $endpoint = $endpoint -replace "\/$", ""
    if ($endpoint -notmatch "^https://api.[a-z0-9\.]+\.sumologic.com$") {
        Write-Error "endpoint: $endpoint must be a valid API endpoint: not match ^https://api.[a-z0-9\.]+\.sumologic.com$"
        #exit 1
    }
    $uri = (@($endpoint, 'api/v2', 'content/folders/personal') -join "/") -replace '//v2', '/v2'
    Write-Verbose "establish session to: $uri for $accessid"
    $res = Invoke-WebRequest -Uri $uri -method Get -Credential $Credential -SessionVariable webSession
    if ($res) {
        # export the default session object to shell
        $Script:sumo_session = [SumoAPISession]::new($endpoint, $webSession, $name, $isAdminMode)
        return $sumo_session
    }
    else {
        Write-Error "session failed." ; 
        #exit 1
    }
}


function getQueryString([hashtable]$form) {
    $sections = $form.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
        "{0}={1}" -f ([System.Web.HttpUtility]::UrlEncode($_.Name)), ([System.Web.HttpUtility]::UrlEncode($_.Value))
    }
    $sections -join "&"
}


<#
    .DESCRIPTION
    Wrapper to make calls to Sumo Logic API
        
    .SYNOPSIS
    Simplifies making calls to the sumologic content api.
    
    .PARAMETER path
    Path to be appended to 'https://endpoint/api/v2'
    
    .PARAMETER session
    Specify a session. 
    
    .PARAMETER method
    HTTP method default GET
    
    .PARAMETER params
    hashtable query params (optional)
    
    .PARAMETER body
    body - encode as json string first.

    .EXAMPLE
    invoke-sumo -path "content/folders/personal"

    .EXAMPLE
    invoke-sumo -path "content/folders/personal"  -session $s1

    .EXAMPLE
    invoke-sumo -path "content/path" -params @{ 'path' = $path;}

#>
function invoke-sumo {
    param(
        [parameter()][SumoAPISession]$session,
        [parameter(Mandatory)][string] $path,
        [parameter()][string] $method = 'GET',
        [parameter()][Hashtable] $params,
        [parameter()]$body,
        [parameter()][string] $v = "v2",
        [parameter()][Hashtable] $headers
    )

    if ($session -and $session.endpoint) { 
        if ($headers) { } else {
            $headers = @{
                "content-type" = "application/json";
                "accept"       = "application/json";
                "isAdminMode"  = $session.isAdminMode
            }
        }

        $uri = (@($session.endpoint, "api/$v", $path) -join "/") -replace '//v', '/v'
        write-verbose "session: $($session.name) invoke_sumo $uri $method isAdminMode: $($session.isAdminMode)"
        if ($params) {
            $qStr = getQueryString($params)
            $uri += "?" + $qStr
        }

        Write-Verbose "headers:`n$($headers | convertto-json -depth 10 -compress)"
        if ($body) {
            if ($body.gettype().Name -eq "String") {
                # it's already probably json
            }
            else {
                $body = $body | ConvertTo-Json -Depth 10 -Compress
            }
            write-verbose "body: `n$body"
            $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -Body $body).Content | convertfrom-json -Depth 10
    
        }
        else {
            $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers  ).Content | convertfrom-json -Depth 10
        }
    }
    else {
        Write-Error "you must supply a valid session object to invoke-sumo"
    }
    # often there is an embedded data object
    if ($r.data) { 
        return $r.data 
    } elseif ($r.collector) {
        return $r.collector
    } elseif ($r.collectors) {
        return $r.collectors
    } elseif ($r.sources) {
        return $r.sources
    } elseif ($r.source) {
        return $r.source
    } elseif ($r.apps) {
        return $r.apps
    }
    else {
        return $r
    }
}

<#
    .DESCRIPTION
    Replaces properties in second object with properties in the first object.
    Also optionally you can substitute text anywhere in the JSON-ified version of the from object using -replace -with
    Function will return a new instance of -to object.

    .PARAMETER from
    source object (typically say a source or collector)

    .PARAMETER to
    to object (typically say a source or collector)

    .PARAMETER replace_pattern
    literal text or pattern to replace text using -replace in the JSON-ified to objct
    
    .PARAMETER with
    text to replace with

    .EXAMPLE
    replace any text in the target object with new text
    copy-proppy -to $mysource -replace_pattern 'test' -with 'prod'
    
    .OUTPUTS
    PSCustomObject.
#>
function copy-proppy {
    param (
        [Parameter(Mandatory = $false)] $from,
        [Parameter(Mandatory = $true)]$to,
        [Parameter(Mandatory = $false)] $props = @("filters", "manualPrefixRegexp", "defaultDateFormats", "name", "description"),
        [Parameter(Mandatory = $false)]$replace_pattern,
        [Parameter(Mandatory = $false)]$with

    )

    write-verbose ($from | out-string)
    write-verbose ($to | out-string )
    
    if ($replace_pattern -and $with ) {
        $new = ($to | ConvertTo-Json -Depth 10) -replace $replace_pattern, $with 
        $out = $new | ConvertFrom-Json -Depth 10
       
    }
    else {
        $out = $to | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

    }
    if ($from -and $props) {
        foreach ($p in $props) {
            $out.$p = $from.$p
        }
    }

    return $out
}

function convertSumoDecimalContentIdToHexId {
    param (
        [Parameter(Mandatory = $true)]$id
    )
    return ('{0:X16}' -f $id)
}