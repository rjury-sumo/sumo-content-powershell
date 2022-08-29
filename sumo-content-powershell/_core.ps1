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
    Two sessions s1 and s2. Provide -sumo_session param to commands to specify instance.
    $s1 =  new-ContentSession -endpoint 'https://api.au.sumologic.com' 
    $s2 =  new-ContentSession -accessid $env:SUMO_ACCESS_ID_BE -accesskey $env:SUMO_ACCESS_KEY_BE  
    $parent_folder = get-PersonalFolder -sumo_session $s1 
    $parent_folder = get-PersonalFolder -sumo_session $s2
    
#>

#if (-not ([System.Management.Automation.PSTypeName]'SumoAPISession').Type) {
try { [SumoAPISession] | Out-Null } catch {
    Add-Type -TypeDefinition  @"
public class SumoAPISession
{
    public SumoAPISession(string Endpoint, object WebSession, string Name, string isAdminMode, string PersonalFolderId) {
        this.Endpoint = Endpoint;
        this.WebSession = WebSession;
        this.Name = Name;
        this.isAdminMode = isAdminMode;
        this.PersonalFolderId = PersonalFolderId;
    }
    public string Endpoint;
    public object WebSession;
    public string Name;
    public string isAdminMode;
    public string PersonalFolderId;
}
"@ 
}

$global:scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

<#
    .DESCRIPTION
    Create a new sumo session object.

    .PARAMETER endpoint
    API endpoint such as https://api.us2.sumologic.com.
    defaults to: $env:SUMO_DEPLOYMENT

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
        [parameter(Mandatory = $false)][string] $endpoint = $env:SUMO_DEPLOYMENT,
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
        $Script:sumo_session = [SumoAPISession]::new($endpoint, $webSession, $name, $isAdminMode, ($res.Content | convertfrom-json -depth 10).id)
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
    By default returns the .Content object converted from JSON
    
    .PARAMETER path
    Path to be appended to 'https://endpoint/api/v2'
    
    .PARAMETER session
    Specify a session. Defaults to global sumo_session object from last New-ContentSession call.
    
    .PARAMETER method
    HTTP method default GET
    
    .PARAMETER params
    hashtable query params (optional)
    
    .PARAMETER body
    body. You can pass either an object or a string of JSON.

    .PARAMETER returnResponse
    boolean - if set to true will return the whole response object rather than .Content converted to JSON

    .PARAMETER filePath
    path of a file to execute where required action is -outfile to this path.

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
        [parameter()][Hashtable] $headers,
        [parameter()][bool]$returnResponse = $false #,
  #      [parameter()][string] $filepath
    )

    if ($session -and $session.endpoint) { 
        if ($headers) { } else {
            $headers = @{
                "content-type" = "application/json";
                "accept"       = "*/*";
                "isAdminMode"  = $session.isAdminMode
            }
        }

        $uri = (@($session.endpoint, "api/$v", $path) -join "/") -replace '//v', '/v'
        write-verbose "session: $($session.name) invoke_sumo $uri $method isAdminMode: $($session.isAdminMode)"
        if ($params) {
            $qStr = getQueryString($params)
            $uri += "?" + $qStr
        }

        Write-Verbose "headers:`n$($headers | convertto-json -depth 100 -compress)"
        if ($body) {
            if ($body.gettype().Name -eq "String") {
                # it's already probably json
            }
            else {
                if ($headers['content-type'] = "application/json") {
                    $body = $body | ConvertTo-Json -Depth 100 -Compress
                }
                else {
                    Write-Verbose "custom body content passed as is due to content-type: $($headers['content-type'])"
                }
            }
            write-verbose "body: `n$body"
            $response = Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -Body $body -SkipHttpErrorCheck
    
  #      }
 #       elseif ($filepath) {
 #           $response = Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -SkipHttpErrorCheck -OutFile "$filepath"

        } else {
            $response = Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -SkipHttpErrorCheck
        }
    }
    else {
        Write-Error "you must supply a valid session object to invoke-sumo"
        break
    }

    Write-Verbose ($response | Out-String)

    #if ($response.statuscode -gt 0 -and $returnResponse -ne 1) {
    if ($response.statuscode -gt 399) {
        Write-Error "invoke-sumo $uri returned: $($response.statuscode) StatusDescription $($response.StatusDescription) `n$" -ErrorAction Stop
        return $response
    }

    if ($returnResponse) {
        Write-Verbose "returning whole response object"
        return $response
    }
    else {
        $r = $response.content | ConvertFrom-Json -Depth 100

        if ($r) {
            #Write-Verbose "`nResponse Content: `n$($response.content)"
            Write-Verbose "return object type: $($r.GetType().BaseType.name)"
            # often there is an embedded data object
            If ($r.GetType().BaseType.name -match "Array") { 
                return $r
            }
            elseif ($r.data) { 
                return $r.data 
            }
            elseif ($r.collector) {
                return $r.collector
            }
            elseif ($r.collectors) {
                return $r.collectors
            }
            elseif ($r.sources) {
                return $r.sources
            }
            elseif ($r.source) {
                return $r.source
            }
            elseif ($r.apps) {
                return $r.apps
            }
            else {
                return $r
            }
        }
        else {
            Write-Verbose "null content object"
            return @()
        }
    }
    
}

<#
    .DESCRIPTION
    Returns a clone of the $to object.
    
    with -props and -from 
    will copy properties from to cloned object
    
    with -replace_props, -replace_pattern, -with 
    Text substitution of properties specified in either regex mode (default) or with -replace_mode 'text' change a text only mode.
    If the property substitution is for a string property text replace is vs the string value.
    Otherwise the replace is vs a 'json-ified' string of the object, which is then converted-back from json.

    .PARAMETER from
    source object (typically say a dashboard, ource, collector)

    .PARAMETER to
    optional target object to clone from. If none is supplied 'from' is cloned as base.

    .PARAMETER replace_props
    optional: property array in which to replace using replace_pattern and with.

    .PARAMETER replace_pattern
    requires replace_props
    pattern of text to replace. if property is string replacement is vs string, if not is vs a 'json-ified' verion of the object.
    
    .PARAMETER mode
    requires replace_props
    choose between default regex or string mode
    
    .PARAMETER with
    requires replace_props
    text to replace with

    .EXAMPLE
    copy-proppy -from $my_dashboard -replace-props @('title','description') -replace_pattern 'test' -with 'prod'
    clone the 'from' dasboard object and return a new object with replacements of text in title and description properties.
    
    .EXAMPLE
    copy-proppy -from $resource['source'] -to $resource['source2'] -props @("name")
    Copies a property 'name' from one source to another, outputting a new object.

    .OUTPUTS
    PSCustomObject.
#>
function copy-proppy {
    param (
        [Parameter(Mandatory = $false)] $from,
        [Parameter(Mandatory = $true)] $to,
        [Parameter(Mandatory = $false)] $props = @("filters", "manualPrefixRegexp", "defaultDateFormats", "name", "description"),
        [Parameter(Mandatory = $false)] $replace_props = @(),
        [Parameter(Mandatory = $false)] $replace_pattern,
        [Parameter(Mandatory = $false)] $replace_mode = 'regex',
        [Parameter(Mandatory = $false)] $with

    )

    #write-verbose ($from | out-string)
    #write-verbose ($to | out-string )
    
    # make a new copy of the object
    # note $to is optional
    if ($from -eq $null ) {
        $from = $to | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100  
    } 

    $out = $from | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10  

    if ($props -and ( compare-object -DifferenceObject $from -ReferenceObject $to -IncludeEqual) -eq $false ) {
        foreach ($p in $props) {
            $out.$p = $from.$p
        }
    }
    
    # do replacements on properties if requested.
    if ($from -and $replace_props) {
        foreach ($p in $replace_props) {
            if (($out.$p).gettype().name -eq 'String') {
                if ($replace_mode -eq 'regex') {
                    $out.$p = ($out.$p) -replace $replace_pattern, $with 
                }
                else {
                    $out.$p = ($out.$p).replace($replace_pattern, $with)
                }
            }
            else {
                Write-Verbose "try json replace on non-string property $p.getenumerator()"
                if ($replace_mode -eq 'regex') {
                    $out.$p = (($out.$p | ConvertTo-Json -Depth 100) -replace $replace_pattern, $with ) | convertfrom-json -depth 100
                }
                else {
                    $out.$p = (($out.$p | ConvertTo-Json -Depth 20).replace($replace_pattern, $with) ) | convertfrom-json -depth 100
                }
            }
        }
    }

    # return a new object
    return $out
}

function convertSumoDecimalContentIdToHexId {
    param (
        [Parameter(Mandatory = $true)]$id
    )
    return ('{0:X16}' -f $id)
}


function New-MultipartBoundary {
    $boundary = [System.Guid]::NewGuid().ToString(); 
    return $boundary
}
function New-MultipartContent {
    param(
        [Parameter(Mandatory)]
        $FilePath,
        [string]$HeaderName = 'file',
        $boundary = [System.Guid]::NewGuid().ToString()
    )
    
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath);
    $fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);
   
    $LF = "`r`n";

    $bodyLines = ( 
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$((dir $filepath).Name)`"",
        "Content-Type: application/octet-stream$LF",
        $fileEnc,
        "--$boundary--$LF" 
    ) -join $LF
    return (@{ "multipartBody" = $bodyLines; "boundary" = $boundary })
}

# returns the index of an array using name pattern for a list of objects or hashes.
function getArrayIndex ($array, $namePattern) {
    $i = -1
    foreach ($element in $array) { 
        $i = $i + 1
        If ($element.name -match $namePattern) {
            return $i
        }
    }
    return -1
}


<#
    .DESCRIPTION
    Sometimes it's handy to convert something to jaon and replace all occurrences of pattern A with string B
    That is what this function does.

    .PARAMETER in
    source string or PS Object. This will be converted to JSON before running substitutions.

    .PARAMETER substitutions
    an array of substitution hashes. Each hash should have a replace and with key.
    replace is the regular expression to match the replace text
    with is the string to substitute for the matching pattern.

    .EXAMPLE
    replace both foo with bar and red with blue in the object.
    batchReplace -in 'foo bar i have a red apple' -substitutions @(@{'replace'='foo';'with'='bar'},@{'replace'='red';'with'='blue'};)
    
    .OUTPUTS
    PSCustomObject.
#>

function batchReplace {
    param (
        [Parameter(Mandatory = $true)] $in,
        [Parameter(Mandatory = $true)][array]$substitutions
    )
    
    $json = $in | convertto-json -depth 100
    foreach ($sub in $substitutions) {
        if (-not $sub.contains('replace')) { 
            Write-Error "sub object missing replace in $($sub | out-string)"
            return $in
        }
        if (-not $sub.contains('with')) { 
            Write-Error "sub object missing with in $($sub | out-string)"
            return $in
        }

        $json = $json -replace $sub['replace'], $sub['with']
    }

    $out = $json | ConvertFrom-Json -Depth 100
    return $out
}