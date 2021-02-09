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
        [parameter()][bool]$returnResponse = $false
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

        Write-Verbose "headers:`n$($headers | convertto-json -depth 100 -compress)"
        if ($body) {
            if ($body.gettype().Name -eq "String") {
                # it's already probably json
            }
            else {
                if ($headers['content-type'] = "application/json") {
                    $body = $body | ConvertTo-Json -Depth 100 -Compress
                } else {
                    Write-Verbose "custom body content passed as is due to content-type: $($headers['content-type'])"
                }
            }
            write-verbose "body: `n$body"
            $response = Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -Body $body -SkipHttpErrorCheck
    
        }
        else {
            $response = Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -SkipHttpErrorCheck
        }
    }
    else {
        Write-Error "you must supply a valid session object to invoke-sumo"
        break
    }

    Write-Verbose ($response | Out-String)

    if ($response.statuscode -gt 0 ) {
        if ($response.statuscode -gt 399) {
            Write-Error "invoke-sumo $uri returned: $($response.statuscode) $($response.content)"
            return $response
        }

    } else {
        Write-Error "invoke-sumo $uri request failed"
        return @()
    }

    if ($returnResponse) {
        return $response
    } else {
        $r = $response.content | ConvertFrom-Json -Depth 100

        if ($r) {
            #Write-Verbose "`nResponse Content: `n$($response.content)"
            Write-Verbose "return object type: $($r.GetType().BaseType.name)"
            # often there is an embedded data object
            If ($r.GetType().BaseType.name -match "Array") { 
                return $r
            } elseif ($r.data) { 
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
        } else {
            Write-Verbose "null content object"
            return @()
        }
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


function New-MultipartBoundary {
    $boundary = [System.Guid]::NewGuid().ToString(); 
    return $boundary
 }
 function New-MultipartContent {
    param(
        [Parameter(Mandatory)]
        $FilePath,
        [string]$HeaderName='file',
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
    return (@{ "multipartBody" = $bodyLines; "boundary" =  $boundary})
 }

# returns the index of an array using name pattern for a list of objects or hashes.
 function getArrayIndex ($array,$namePattern) {
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
        if (-not $sub.contains('replace'))  { 
            Write-Error "sub object missing replace in $($sub | out-string)"
            return $in
        }
        if (-not $sub.contains('with'))  { 
            Write-Error "sub object missing with in $($sub | out-string)"
            return $in
        }

        $json = $json -replace $sub['replace'],$sub['with']
    }

    $out = $json | ConvertFrom-Json -Depth 100
    return $out
 }

######################################################### accesskeys.ps1 functions ##############################################################
# auto generated by srcgen accessKeys 11/17/2020 2:22:04 PM 


<#
    .DESCRIPTION
    /v1/accessKeys,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-AccessKeys {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "accessKeys" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-AccessKey {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "accessKeys" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys/personal,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-AccessKeysPersonal {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "accessKeys/personal" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-AccessKeyById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "accessKeys/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-AccessKeyById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "accessKeys/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### apps.ps1 functions ##############################################################
# auto generated by srcgen apps 11/17/2020 2:22:04 PM 


<#
    .DESCRIPTION
    /v1/apps,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Apps {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "apps" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/apps/install/{jobId}/status,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER jobId
     jobId for get
 
     .EXAMPLE
     Get-AppInstallStatusById -jobId 87CDEA205F005A01

     .OUTPUTS
     PSCustomObject. with properties status, statusMessage,error
 #>
 
 
 function Get-AppInstallStatusById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$jobId
     )
     return (invoke-sumo -path "apps/install/$jobId/status" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/apps/{uuid},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER uuid
     uuid for get

     .EXAMPLE
     Get-AppById -uuid deadca25-5fa9-4620-812d-dced60b59ff8
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-AppById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$uuid
     )
     return (invoke-sumo -path "apps/$uuid" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/apps/{uuid}/install,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER uuid
     uuid for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
<#
    .DESCRIPTION
    /v1/apps/{uuid}/install,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER uuid
    uuid for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>

function New-AppInstallById {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$uuid,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "apps/$uuid/install" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
##################################  NON api-gen code ##################################################
<#
    .DESCRIPTION
    /v1/apps/{uuid}/install,post
    Starts a app install job by supplying params rather than a -body via New-AppInstallById 
    To see what apps can be installed use Get-apps and Get-appbyid

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER uuid
    uuid of the app.

    .PARAMETER name
    optional name, defaults to app name defined by uuid

    .PARAMETER description
    app description, defaults to appManifest.description defined by uuid

    .PARAMETER destinationFolderId
    destinationFolderId, defealts to personal folder

    .PARAMETER dataSourceValues
    required parameters for the app such as @{'Log data source' = '_sourcecategory=*'}

    .EXAMPLE
    Install the log analysis quickstart to your personal folder
    Install-SumoApp -uuid deadca25-5fa9-4620-812d-dced60b59ff8 -dataSourceValues @{'Log data source' = '_sourcecategory=*' }

    .OUTPUTS
    PSCustomObject containing ID of install job
#>

function Install-SumoApp {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$uuid,
        [parameter(mandatory = $false)]$name,
        [parameter(mandatory = $false)]$description,
        [parameter(mandatory = $false)]$destinationFolderId,
        [parameter(mandatory = $false)][hashtable]$dataSourceValues = @{'Log data source' = '_sourcecategory=*' }
    )

    # get the app by uuid first
    $app = (Get-AppById -uuid $uuid)
    if ($app.appDefinition) {
        $appDefinition =$app.appDefinition
        $appDefinition | Add-Member -NotePropertyName description -NotePropertyValue $app.appManifest.description
    } else {
        throw "get-appbyid for app $uuid failed. cannot continue with app install."
    }

    # construct the custom body object
    if ($name) { $appDefinition.name = $name }
    if ($description) { $appDefinition.description = $description }
    if ($dataSourceValues) { $appDefinition | Add-Member -NotePropertyName dataSourceValues -NotePropertyValue $dataSourceValues } 
    if ($destinationFolderId) {
        $appDefinition | Add-Member -NotePropertyName destinationFolderId -NotePropertyValue $destinationFolderId 
    }
    else {
        $appDefinition | Add-Member -NotePropertyName destinationFolderId -NotePropertyValue (Get-PersonalFolder).id
    }

    Write-Verbose ($appDefinition |ConvertTo-Json)
    return (invoke-sumo -path "apps/$uuid/install" -method POST -session $sumo_session -v 'v1' -body $appDefinition )
}
 
 
 
 

######################################################### archive.ps1 functions ##############################################################

######################################################### collectors.ps1 functions ##############################################################
<#
    .DESCRIPTION
    get /v1/collectors

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-collectors {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter()][string] $limit = 100,
        [parameter()][string] $offset = 0
        
    )
    return (invoke-sumo -path "collectors" -session $sumo_session -v $v -params @{'limit' = $limit; 'offset' = $offset })
}


<#
    .DESCRIPTION
    get /collectors/offline

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-offlineCollectors {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "collectors/offline" -session $sumo_session -v $v ).collectors
}

<#
    .DESCRIPTION
    get /v1/collectors/{id}

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-collectorById {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)] $id
        
    )
    return (invoke-sumo -path "collectors/$id" -session $sumo_session -v $v ).collector
}


<#
    .DESCRIPTION
    get /v1/collectors/name/[name]

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-collectorByName {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)][string] $Name
        
    )
    $encodedName = [System.Web.HttpUtility]::UrlEncode($name) 
    return (invoke-sumo -path "collectors/name/$encodedName/" -session $sumo_session -v $v )
}

######################################################### connections.ps1 functions ##############################################################
# auto generated by srcgen connections 11/17/2020 2:22:04 PM 


<#
    .DESCRIPTION
    /v1/connections,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Connections {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "connections" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/connections,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-Connection {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "connections" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/connections/test,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-ConnectionTest {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "connections/test" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/connections/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-ConnectionById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)][ValidateSet('WebhookConnection','ServiceNowConnection')]$type 
         
     )
     return (invoke-sumo -path "connections/$id" -method DELETE -session $sumo_session -v 'v1' -params @{'type' = $type})
 }
 
 <#
     .DESCRIPTION
     /v1/connections/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-ConnectionById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "connections/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/connections/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-ConnectionById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "connections/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### content.ps1 functions ##############################################################

<#
    .DESCRIPTION
    get content item using path.
    NOTE: getting a folder by path does NOT return the chidren property.
    If you want to recurse folders use get by 'get-Folder -id $id' instead!

    .PARAMETER path
    content path

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-ContentByPath -path '/Library/Users/user@acme.com/folder/item' 

    .OUTPUTS
    PSCustomObject. returns content object
#>

function get-ContentByPath {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $path 
    )
    return invoke-sumo -path "content/path" -params @{ 'path' = $path; } -session $sumo_session
}


<#
    .DESCRIPTION
    get path of an item using id

    .PARAMETER id
    content id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-ContentPath -id '0000000000123526'

    .OUTPUTS
    System.String. returns string path for object such as: /Library/Users/user@acme.com/folder/item
#>
function get-ContentPath {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $id 
    )
    return (invoke-sumo -path "content/$id/path" -session $sumo_session).path 
}


<#
    .DESCRIPTION
    Start a content export job using content id

    .PARAMETER id
    content id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    Hashtable. keys: contentid; jobId
#>
function start-ContentExportJob {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $id 
    )
    return @{'contentId' = $id; 'jobId' = (invoke-sumo -path "content/$id/export/" -method 'POST' -session $sumo_session).id } 
}


<#
    .DESCRIPTION
    Get status of a content export job

    .PARAMETER id
    content id

    .PARAMETER job
    export job id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-contentExportJobStatus -job '4EA1C8F29371B157'-id '0000000000AB8526'

    .OUTPUTS
    PSCustomObject. Job status, including 'status' field

    #>
function get-ContentExportJobStatus {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $job,
        [parameter(Mandatory = $true)][string] $id

    )
    return invoke-sumo -path "content/$id/export/$job/status" -method 'GET' -session $sumo_session
}


<#
    .DESCRIPTION
    Get generated output of a completed export job.
    Use with ConvertTo-Json -Depth 100 to export as importable JSON.

    .PARAMETER id
    content id

    .PARAMETER job
    export job id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-ContentExportJobResult -job '4EA1C8F29371B157'-id '0000000000AB8526' | Convertto-JSON Depth 100

    .OUTPUTS
    PSCustomObject. Content of the export job. 
#>
function get-ContentExportJobResult {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $job,
        [parameter(Mandatory = $true)][string] $id

    )
    return invoke-sumo -path "content/$id/export/$job/result" -method 'GET' -session $sumo_session
}


<#
    .DESCRIPTION
    Start a content export job, poll for completion and return the completed export object.

    .PARAMETER id
    content id

    .PARAMETER poll_secs
    sleep time for status poll
    
    .PARAMETER max_tries
    number of polling attempts before giving up.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    (get-ExportContent -id $export_id ) | ConvertTo-Json -Depth 100

    .OUTPUTS
    PSCustomObject. Content of the export job. 
#>
function get-ExportContent {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $id ,
        [parameter(Mandatory = $false)][string] $poll_secs = 1,
        [parameter(Mandatory = $false)][string] $max_tries = 15
    )
    $job = start-ContentExportJob -id $id -sumo_session $sumo_session
    $tries = 0

    While (($job) -and ($max_tries -gt $tries)) {
        $tries = $tries + 1     
        Write-Verbose "polling id: $id $($job['jobId']). try: $tries of $max_tries"
        $job_state = get-ContentExportJobStatus -job $job['jobId'] -id $id -sumo_session $sumo_session
        Write-Verbose  ($job_state.status)
        if ($job_state.status -eq 'Success') {
            
            break
        }
        else {
            Start-Sleep -Seconds $poll_secs
        }
    }   
    Write-Verbose "job poll completed: status: $($job_state.status) contentId: $id jobId: $($job['jobId'])"
    if ($job_state.status -eq 'Success') {
        $result = get-ContentExportJobResult -job $job['jobId'] -id $id -sumo_session $sumo_session
    }
    else { Write-Error 'Job failed or timed out'; }
    return  $result
}


<#
    .DESCRIPTION
    Start a content copy job 

    .PARAMETER id
    content id

    .PARAMETER destinationFolder
    destinationFolder id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    gestartt-contentCopyJob -id '0000000000AB8526'

    .OUTPUTS
    Hashtable. keys: contentid; jobId, destinationFolder
#>
function start-ContentCopyJob {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $id ,
        [parameter(Mandatory = $true)][string] $destinationFolder 
    )
    return @{'contentId'    = $id; 
        'jobId'             = (invoke-sumo -path "content/$id/copy" -method 'POST' -session $sumo_session  -params @{ 'destinationFolder' = $destinationFolder; }).id ; 
        'destinationFolder' = $destinationFolder;
    } 
}

<#
    .DESCRIPTION
    Get status of a content copy job

    .PARAMETER id
    content id

    .PARAMETER job
    copy job id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-contentCopyJobStatus -job '4EA1C8F29371B157' -id '0000000000AB8526'

    .OUTPUTS
    PSCustomObject. Job status, including 'status' field

    #>
function get-ContentCopyJobStatus {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $job,
        [parameter(Mandatory = $true)][string] $id

    )
    return invoke-sumo -path "content/$id/copy/$job/status" -method 'GET' -session $sumo_session
}

<#
    .DESCRIPTION
    Start a content Import job using content id

    .PARAMETER id
    content id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER contentJSON
    Content in JSON format sent as body. Note if this is from a file use gc -Path ./temp.json -Raw

    .PARAMETER overwrite
    bool string defaults to false, sets true to overwrite.

    .OUTPUTS
    Hashtable. keys: folderId; jobId
#>
function start-ContentImportJob {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $folderId ,
        [parameter(Mandatory = $true)] $contentJSON ,
        [parameter(Mandatory = $false)][string] $overwrite = 'false'

    )
    return @{'folderId' = $folderId; 'jobId' = (invoke-sumo -path "content/folders/$folderId/import" -method 'POST' -session $sumo_session -Body $contentJSON -params @{ 'overwrite' = $overwrite ; }).id } 
}

<#
    .DESCRIPTION
    /v2/content/folders/{folderId}/import/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER folderId
    folderId for get

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersImportStatusById {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$folderId,
         [parameter(mandatory=$True)]$jobId
     )
     return (invoke-sumo -path "content/folders/$folderId/import/$jobId/status" -method GET -session $sumo_session -v 'v2')
 }

<#
    .DESCRIPTION
    /v2/content/{id}/move,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for post

    .PARAMETER destinationFolderId
    id of target folder to move to

    .OUTPUTS
    PSCustomObject.
#>

function Move-ContentById {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$destinationFolderId
    )
    return (invoke-sumo -path "content/$id/move" -method POST -session $sumo_session -v 'v2' -body $body -params @{"destinationFolderId" = $destinationFolderId })
}
 
 <#
    .DESCRIPTION
    /v2/content/folders/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .EXAMPLE
    Get-ContentFolderById -id ((get-personalfolder).children | where {$_.name -match '^api-create-test$'}).id

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFolderById {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "content/folders/$id" -method GET -session $sumo_session -v 'v2')
 }
 

<#
    .DESCRIPTION
    /v2/content/folders/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-ContentFoldersById {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "content/folders/$id" -method PUT -session $sumo_session -v 'v2' -body $body )
 }
 

 

######################################################### dashboards.ps1 functions ##############################################################
# auto generated by srcgen dashboards 11/17/2020 2:22:05 PM 


<#
    .DESCRIPTION
    /v2/dashboards,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-Dashboard {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "dashboards" -method POST -session $sumo_session -v 'v2' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v2/dashboards/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-DashboardById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "dashboards/$id" -method DELETE -session $sumo_session -v 'v2')
 }
 
 <#
     .DESCRIPTION
     /v2/dashboards/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-DashboardById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "dashboards/$id" -method GET -session $sumo_session -v 'v2')
 }
 
 <#
     .DESCRIPTION
     /v2/dashboards/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-DashboardById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "dashboards/$id" -method PUT -session $sumo_session -v 'v2' -body $body )
 }
 
 


<#
    .DESCRIPTION
    undocumented api to map content id to dashboard id.
    /v2/dashboard/contentId,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get. note this is a url id string e.g Tfj7djZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8 not a content id format.

    .EXAMPLE
    Get-DashboardById -id Tfj7djZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8 -sumo_session $be 

    .OUTPUTS
    PSCustomObject.
#>


function Get-DashboardContentIdById {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     $decimalid = (invoke-sumo -path "dashboard/contentId/$id" -method GET -session $sumo_session -v 'v1alpha')
     return (convertSumoDecimalContentIdToHexId $decimalid )
 }

 <#
    .DESCRIPTION
    substitute all strings matching a regular expression in panels with a new string.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER pattern
    the regular expression pattern that we are going to match in each panel query.

    .PARAMETER replacewith
    the string to replace the matching pattern with.

    .EXAMPLE
    Get-DashboardById -id Tfj7djZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8 -sumo_session $be 

    .OUTPUTS
    PSCustomObject. A new dashboard object with substitutions.
#>
 function Edit-DashboardPanelQueries {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$dashboard,
         [parameter(mandatory=$True)][string]$pattern,
         [parameter(mandatory=$True)][string]$replacewith

     )

     if ($dashboard.panels) {

        # make a fresh dashboard so we don't trash the origional one in memory.
        $newdash = $dashboard | convertto-json -depth 100 | ConvertFrom-Json -Depth 100

         $p=-1
        foreach ($panel in $dashboard.panels) {
            $p = $p +1
            $q = -1
            $changes = 0
            foreach ($query in $panel.queries) {
                $q = $q + 1
                        if ($query -match $pattern) {
                            Write-Verbose "matching panel: $p, query $q replacement: $pattern in $query`n"
                            $changes = $changes + 1
                            $newdash.panels[$p].queries[$q] = $query -replace  $pattern,$replacewith
                }
            }
        }
        Write-Verbose "made $changes changes in $($p + 1) panels in $($q +1 ) queries found."
        return $newdash 
     } else {
         Write-Error "Dashboard is invalid must be a dashboard object with panels attribute."
     }
 }

######################################################### fieldextrationrules.ps1 functions ##############################################################
# auto generated by srcgen extractionRules 11/17/2020 2:22:05 PM 



<#
    .DESCRIPTION
    /v1/extractionRules,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER limit
    rows to return max 1000

    .PARAMETER token
    Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results

    .OUTPUTS
    PSCustomObject.
#>


function Get-ExtractionRules {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter()][string] $limit = 200,
         [parameter()][string] $token
         
     )
     if ($token) {
         $params = @{'limit' = $limit; 'token' = $offset }
     } else {
         $params = @{'limit' = $limit; }
     }
     return (invoke-sumo -path "extractionRules" -method GET -session $sumo_session -v 'v1' -params $params)
 }
 
 
 <#
     .DESCRIPTION
     /v1/extractionRules,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-ExtractionRule {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "extractionRules" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/extractionRules/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-ExtractionRuleById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "extractionRules/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/extractionRules/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-ExtractionRuleById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "extractionRules/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/extractionRules/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-ExtractionRuleById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "extractionRules/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### fields.ps1 functions ##############################################################
# auto generated by srcgen fields 11/16/2020 5:28:46 PM 


<#
    .DESCRIPTION
    /v1/fields,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Fields {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "fields" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-Field {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$name
     )
     return (invoke-sumo -path "fields" -method POST -session $sumo_session -v 'v1' -body @{ "fieldName" = $name} )
 }
 
 <#
     .DESCRIPTION
     /v1/fields/builtin,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-FieldsBuiltin {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "fields/builtin" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/builtin/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-FieldBuiltinById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "fields/builtin/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/dropped,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-FieldsDropped {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "fields/dropped" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/quota,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-FieldsQuota {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "fields/quota" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Delete-FieldById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "fields/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-FieldById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "fields/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/{id}/disable,delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-FieldDisableById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "fields/$id/disable" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/fields/{id}/enable,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-FieldEnableById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "fields/$id/enable" -method PUT -session $sumo_session -v 'v1' -body ($body | ConvertTo-Json -depth 10) )
 }
 
 

######################################################### folders.ps1 functions ##############################################################
<#
    .DESCRIPTION
    get /v2/content/folders/{id}

    .PARAMETER id
    content id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-Folder -id '0000000000123526'

    .OUTPUTS
    PSCustomObject. returns personal folder object
#>
function get-Folder {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $id 
        
    )
    return invoke-sumo -path "content/folders/$id" -session $sumo_session
}


<#
    .DESCRIPTION
    get personal folder as an object.
        
    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-PersonalFolder

    .EXAMPLE
    $parent_folder = get-PersonalFolder
    $FolderNameToExport = "MyFolder"
    $export_id = ($parent_folder.children | where {$_.ItemType -eq "Folder" -and $_.name -eq $FolderNameToExport}).id

    .OUTPUTS
    PSCustomObject. returns personal folder object
#>
function get-PersonalFolder {
    param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return invoke-sumo -path "content/folders/personal" -session $sumo_session
}


<#
    .DESCRIPTION
    get global folder /v2/content/folders/global
        
    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-GlobalFolder

    .EXAMPLE
    $parent_folder = get-GlobalFolder

    .OUTPUTS
    PSCustomObject. returns GlobalFolder object
#>
function get-GlobalFolder {
    param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return invoke-sumo -path "content/folders/global" -session $sumo_session
}

<#
    .DESCRIPTION
    get global folder /v2/content/folders/adminRecommended
        
    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-adminRecommended

    .EXAMPLE
    $parent_folder = get-adminRecommended

    .OUTPUTS
    PSCustomObject. returns adminRecommended object
#>
function get-adminRecommended {
    param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return invoke-sumo -path "content/folders/adminRecommended" -session $sumo_session
}


<#
    .DESCRIPTION
    Get status of a folder job

    .PARAMETER jobid
    export job id

    .PARAMETER type
    global or adminRecommended

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-folderJobStatus -jobid '4EA1C8F29371B157'

    .OUTPUTS
    PSCustomObject. Job status, including 'status' field

    #>
function get-folderJobStatus {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $jobid,
        [parameter(Mandatory = $false)][ValidateSet('global', 'adminRecommended')][string] $type = "global"
    
    )
    return invoke-sumo -path "content/folders/$type/$jobid/status" -method 'GET' -session $sumo_session
}
    
<#
        .DESCRIPTION
        Get generated output of a global folder job.
    
        .PARAMETER jobid
        jobid 
    

        .PARAMETER type
        global or adminRecommended

        .PARAMETER sumo_session
        Specify a session, defaults to $sumo_session
    
        .EXAMPLE
        get-folderJobResult -jobid '4EA1C8F29371B157'
    
        .OUTPUTS
        PSCustomObject. Content of the export job, includes a data key
    #>
function get-folderJobResult {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $jobid,
        [parameter(Mandatory = $false)][ValidateSet('global', 'adminRecommended')][string] $type = "global"
    
    )
    return invoke-sumo -path "content/folders/$type/$jobid/result" -method 'GET' -session $sumo_session
}
    
    
<#
        .DESCRIPTION
        Start a global folder job, poll for completion and return the completed export object.
        global returns list of children, isadminRecommended returns a folder object with children property.
        as per https://api.au.sumologic.com/docs/#operation/getAdminRecommendedFolderAsyncResult

        .PARAMETER type
        global or adminRecommended

         .PARAMETER poll_secs
        sleep time for status poll
        
        .PARAMETER max_tries
        number of polling attempts before giving up.
    
        .PARAMETER sumo_session
        Specify a session, defaults to $sumo_session
    
        .EXAMPLE
        get-folderContent -type global
    
        .OUTPUTS
        PSCustomObject. Content of the export job. 
    #>
function get-folderContent {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $false)][string] $poll_secs = 1,
        [parameter(Mandatory = $false)][string] $max_tries = 15,
        [parameter(Mandatory = $false)][ValidateSet('global', 'adminRecommended')][string] $type = "global"
    )
    if ($type -eq 'global') {
        $jobid = (get-GlobalFolder -sumo_session $sumo_session).id
    }
    else {
        $jobid = (get-adminRecommended -sumo_session $sumo_session ).id 
    }

    $tries = 0
    
    While (($jobid) -and ($max_tries -gt $tries)) {
        $tries = $tries + 1     
        Write-Verbose "polling $jobid try: $tries of $max_tries"
        $job_state = get-folderJobStatus -job $jobid  -type $type -sumo_session $sumo_session
        Write-Verbose  ($job_state.status)
        if ($job_state.status -eq 'Success') {
                
            break
        }
        else {
            Start-Sleep -Seconds $poll_secs
        }
    }   
    Write-Verbose "job poll completed: status: $($job_state.status) jobId: $($jobid)"
    if ($job_state.status -eq 'Success') {
        $result = get-folderJobResult -job $jobid  -type $type  -sumo_session $sumo_session
    }
    else { Write-Error 'Job failed or timed out'; return $false }
    Write-Verbose ($result | convertto-json)
    if ($type -eq 'global') { return $result } else { return $result }
}


<#
    .DESCRIPTION
    create a new folder
        
    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    new-folder -parentId (get-PersonalFolder -sumo_session $s3).id -name 'api-create-test'

    .OUTPUTS
    PSCustomObject. 
#>
function new-folder {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $parentId,  
        [parameter(Mandatory = $true)][string] $name, 
        [parameter(Mandatory = $false)][string] $description = 'no description' ,
        [parameter(Mandatory = $false)][bool] $checkfirst = $false
    )

    $body = @{ 
        "name"        = $name;
        "parentId"    = $parentId; 
        "description" = $description;
    } 

    if ($checkfirst) {
        $itemPath = (get-ContentPath -id $parentId ) + "/" + $name
        if (get-ContentByPath -path $itemPath -ErrorAction SilentlyContinue ) { return $true } 
    }
    
    return invoke-sumo -path "content/folders" -method 'POST' -session $sumo_session -Body $body 

}

######################################################### healthevents.ps1 functions ##############################################################
# auto generated by srcgen healthEvents 11/17/2020 2:22:05 PM 
# modified nov 20 with custom code for query strings.

<#
    .DESCRIPTION
    /v1/healthEvents,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER limit
    rows to return max 1000

    .PARAMETER token
    Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results

    .OUTPUTS
    PSCustomObject.
#>


function Get-HealthEvents {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $limit,
        [parameter()][string] $token
    )
    $params = @{}
    if ($limit) {
        $params['limit'] = $limit
    }
    if ($token) {
        $params['token'] = $token 
    }
    return (invoke-sumo -path "healthEvents" -method GET -session $sumo_session -v 'v1' -params $params)
}
 
<#
     .DESCRIPTION
     /v1/healthEvents/resources,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post

    .PARAMETER limit
    rows to return max 1000

    .PARAMETER token
     Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results

    .EXAMPLE
     Get-HealthEventResources -sumo_session $be -body @{'data'=@(@{'id'='00000000234561C1'; 'name'='sumo'; 'type'='Source';})}
 
    .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-HealthEventResources {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$body,
        [parameter()][string] $limit,
        [parameter()][string] $token
    )
    $params = @{}

    if ($limit) {
        $params['limit'] = $limit
    }
    if ($token) {
        $params['token'] = $token 
    }

    return (invoke-sumo -path "healthEvents/resources" -method POST -session $sumo_session -v 'v1' -body $body -params $params)
}
 
 

######################################################### ingestbudgets.ps1 functions ##############################################################
# auto generated by srcgen ingestBudgets 11/20/2020 9:17:49 AM 
# custom code added for query strings nov 20

<#
    .DESCRIPTION
    /v1/ingestBudgets,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER limit
    rows to return max 1000

    .PARAMETER token
     Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results

    .OUTPUTS
    PSCustomObject.
#>


function Get-IngestBudgetsv1 {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $limit,
        [parameter()][string] $token
    )
    $params = @{}
 
    if ($limit) {
        $params['limit'] = $limit
    }
    if ($token) {
        $params['token'] = $token 
    }
 
    return (invoke-sumo -path "ingestBudgets" -method GET -session $sumo_session -v 'v1' -params $params)
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function New-IngestBudgetsv1 {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "ingestBudgets" -method POST -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-IngestBudgetv1ById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id" -method DELETE -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-IngestBudgetv1ById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id" -method GET -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-IngestBudgetv1ById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "ingestBudgets/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id}/collectors,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-IngestBudgetv1CollectorsById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id/collectors" -method GET -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id}/collectors/{collectorId},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .PARAMETER collectorId
     collectorId for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-IngestBudgetv1CollectorsById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$collectorId
    )
    return (invoke-sumo -path "ingestBudgets/$id/collectors/$collectorId" -method DELETE -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id}/collectors/{collectorId},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER collectorId
     collectorId for put

     .EXAMPLE
     Set-IngestBudgetv1CollectorsById -id 0000000000002A13 -collectorId 109028144
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-IngestBudgetv1CollectorsById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$collectorId
    )

    return (invoke-sumo -path "ingestBudgets/$id/collectors/$collectorId" -method PUT -session $sumo_session -v 'v1' )
}
 
<#
     .DESCRIPTION
     /v1/ingestBudgets/{id}/usage/reset,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post

     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Reset-IngestBudgetv1UsageResetById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id/usage/reset" -method POST -session $sumo_session -v 'v1'  )
}
 
<#
     .DESCRIPTION
     /v2/ingestBudgets,get
 
    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER limit
    rows to return max 1000

    .PARAMETER token
     Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results

    .OUTPUTS
    PSCustomObject.
#>
 
 
function Get-IngestBudgetsv2 {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $limit,
        [parameter()][string] $token
        )
        $params = @{}
     
        if ($limit) {
            $params['limit'] = $limit
        }
        if ($token) {
            $params['token'] = $token 

        }    return (invoke-sumo -path "ingestBudgets" -method GET -session $sumo_session -v 'v2' -params $params)
}
 
<#
     .DESCRIPTION
     /v2/ingestBudgets,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function New-IngestBudgetsv2 {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "ingestBudgets" -method POST -session $sumo_session -v 'v2' -body $body )
}
 
<#
     .DESCRIPTION
     /v2/ingestBudgets/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-IngestBudgetv2ById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id" -method DELETE -session $sumo_session -v 'v2')
}
 
<#
     .DESCRIPTION
     /v2/ingestBudgets/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-IngestBudgetv2ById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id" -method GET -session $sumo_session -v 'v2')
}
 
<#
     .DESCRIPTION
     /v2/ingestBudgets/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-IngestBudgetv2ById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "ingestBudgets/$id" -method PUT -session $sumo_session -v 'v2' -body $body )
}
 
<#
     .DESCRIPTION
     /v2/ingestBudgets/{id}/usage/reset,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Reset-IngestBudgetv2UsageResetById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "ingestBudgets/$id/usage/reset" -method POST -session $sumo_session -v 'v2'  )
}
 
 

######################################################### logssearchestimatedusage.ps1 functions ##############################################################

function Get-LogSearchesEstimatedUsage {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "logSearches/estimatedUsage" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### lookuptables.ps1 functions ##############################################################
# auto generated by srcgen lookupTables 11/20/2020 9:17:48 AM 
# much custom coding in here too

<#
    .DESCRIPTION
    /v1/lookupTables,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER parentFolderId
    parentFolderId such as (get-personalfolder).id

    .PARAMETER description
    description

    .PARAMETER columns
    an arraylist of columns in format:
    @("columna","columnb","columnc")
    which defaults to string type for each or:
     @("columna","columnb=boolean","columnc")
    for a non default data type
    
    .PARAMETER primaryKeys
    primaryKeys arrayLIst. @("a")

    .PARAMETER ttl
    optional ttl nteger <int32> [ 0 .. 525600 ]
    0 default is no ttl.

    .PARAMETER sizeLimitAction
    optional StopIncomingMessages or DeleteOldData

    .PARAMETER dryrum
    set to $true to output a table schema rather than create it.

    .OUTPUTS
    PSCustomObject.
#>

function New-LookupTable {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)][string]$name,
        [parameter(mandatory = $True)][string]$parentFolderId,
        [parameter(mandatory = $True)][string]$description,
        [parameter(mandatory = $True)][System.Collections.ArrayList]$columns,
        [parameter(mandatory = $True)][System.Collections.ArrayList]$primaryKeys,
        [parameter(mandatory = $false)][bigint]$ttl = 0,
        [parameter(mandatory = $false)][string]$sizeLimitAction = 'DeleteOldData',
        [parameter(mandatory = $false)][bool]$dryrun = $false
    )

    $newlookup = '{"description":"sample","fields":[{"fieldName":"a","fieldType":"boolean"}],"primaryKeys":["a"],"ttl":100,"sizeLimitAction":"DeleteOldData","name":"SampleLookupTable","parentFolderId":"01234"}' | ConvertFrom-Json -Depth 10

    [System.Collections.ArrayList]$fields = @()
    foreach ($col in $columns) {
        if ($col -match '=') {
            $fieldName=($col -split '=')[0]
            $fieldType=($col -split '=')[1]
        } else {
            $fieldName=$col 
            $fieldType='string'
        }
        $fields += @{"fieldName"=$fieldName;"fieldType" = $fieldType}
    }

    $newlookup.description = $description
    $newlookup.fields = $fields
    $newlookup.primaryKeys = $primaryKeys
    if ($ttl) { $newlookup.ttl = $ttl }
    if ($sizeLimitAction) { $newlookup.sizeLimitAction = $sizeLimitAction }
    $newlookup.name = $name
    $newlookup.parentFolderId = $parentFolderId
    if ($dryrun) {
        return ($newlookup | ConvertTo-Json -Depth 10)
    } else {
        return (invoke-sumo -path "lookupTables" -method POST -session $sumo_session -v 'v1' -body $newlookup )
    }
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/jobs/{jobId}/status,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER jobId
     jobId for get
 
     .EXAMPLE
     Get-LookupTableJobsStatusById -jobId 64D4336596622921 -sumo_session $abc

     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-LookupTableJobsStatusById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$jobId
    )
    return (invoke-sumo -path "lookupTables/jobs/$jobId/status" -method GET -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-LookupTableById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "lookupTables/$id" -method DELETE -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-LookupTableById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "lookupTables/$id" -method GET -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-LookupTableById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id}/deleteTableRow,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-LookupTableRowById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/deleteTableRow" -method PUT -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id}/row,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function New-LookupTableRowById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/row" -method PUT -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id}/truncate,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function New-LookupTableTruncateById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/truncate" -method POST -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/lookupTables/{id}/upload,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER filepath
     path to csv file. 
 
     .PARAMETER merge
     false default
 
     .PARAMETER fileEncoding
     default "UTF-8"
 
     .EXAMPLE 
     update a lokup table using a csv.
     Set-LookupTableFromCsv -id 0000000001111111 -sumo_session $abc -filepath ./library/lookuptable-example2.csv -Verbose

     .OUTPUTS
     PSCustomObject. ID of job such as 64D4336596622921
 #>
 
 
function Set-LookupTableFromCsv {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$filepath,
        [parameter()][string] $merge,
        [parameter()][string] $fileEncoding = "UTF-8"
    )
    if ($merge) {
        $params['merge'] = $merge
    }
    if ($token) {
        $params['fileEncoding'] = $fileEncoding 
    }
 
    $multipartContent = New-MultipartContent -FilePath $filepath
    $customheaders = @{
        'Content-Type' = "multipart/form-data; boundary=$($multipartContent['boundary'])";
        "accept"       = "application/json"
    }

    return (invoke-sumo -path "lookupTables/$id/upload" -method POST -session $sumo_session -v 'v1' -body $multipartContent['multipartBody'] -params $params -headers $customheaders)
}
 
 

######################################################### metricalertmonitors.ps1 functions ##############################################################
# auto generated by srcgen metricsAlertMonitors 11/20/2020 9:17:48 AM 
# WARNING this code is auto generated and not tested yet.

<#
    .DESCRIPTION
    /v1/metricsAlertMonitors,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-MetricsAlertMonitors {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "metricsAlertMonitors" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/metricsAlertMonitors,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-MetricsAlertMonitor {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "metricsAlertMonitors" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/metricsAlertMonitors/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-MetricsAlertMonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "metricsAlertMonitors/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/metricsAlertMonitors/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MetricsAlertMonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "metricsAlertMonitors/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/metricsAlertMonitors/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-MetricsAlertMonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "metricsAlertMonitors/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/metricsAlertMonitors/{id}/mute,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-MetricsAlertMonitorMuteById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "metricsAlertMonitors/$id/mute" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/metricsAlertMonitors/{id}/unmute,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-MetricsAlertMonitorUnmuteById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "metricsAlertMonitors/$id/unmute" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### metricsearch.ps1 functions ##############################################################
# auto generated by srcgen metricsSearches 11/20/2020 9:17:48 AM 


<#
    .DESCRIPTION
    /v1/metricsSearches,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-MetricsSearch {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "metricsSearches" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/metricsSearches/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-MetricsSearchById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "metricsSearches/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/metricsSearches/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MetricsSearchById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "metricsSearches/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/metricsSearches/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-MetricsSearchById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "metricsSearches/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### monitors.ps1 functions ##############################################################
# auto generated by srcgen monitors 11/20/2020 9:17:48 AM 
# signifigant custom non apigen in this file!

<#
     .DESCRIPTION
     /v1/monitors,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session

     .PARAMETER ids
     a list of ids
 
     .OUTPUTS
     PSCustomObject.

     .EXAMPLE
    Get-MonitorsBulkByIds -ids "0000000000000001,0000000000000002,0000000000000003"
 #>
 
 
 function Get-MonitorsBulkByIds {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(Mandatory=$true)][string]$ids 
     )

    $params =@{'ids' = $ids}

    return (invoke-sumo -path "monitors" -method GET -session $sumo_session -v 'v1' -params $params )
 }


<#
     .DESCRIPTION
     /v1/monitors/path,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session

     .PARAMETER path
     montor or monitor folder object path
 
     .OUTPUTS
     PSCustomObject.

     .EXAMPLE
        Get-MonitorsObjectByPath -path '/Monitor/LB Demo Alerts'
 #>
 
 
 function Get-MonitorsObjectByPath {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(Mandatory=$true)][string]$path 
     )

    if ($path) { 
        $params =@{'path' = $path}
    } else {
        $params =@{}
    }

    return (invoke-sumo -path "monitors/path" -method GET -session $sumo_session -v 'v1' -params $params)
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/root,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MonitorsRoot {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "monitors/root" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/search,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER query
        Example: "createdBy:000000000000968B Test"
        The search query to find monitor or folder. Below is the list of different filters with examples:

        createdBy : Filter by the user's identifier who created the content. Example: createdBy:000000000000968B.
        createdBefore : Filter by the content objects created before the given timestamp(in milliseconds). Example: createdBefore:1457997222.
        createdAfter : Filter by the content objects created after the given timestamp(in milliseconds). Example: createdAfter:1457997111.
        modifiedBefore : Filter by the content objects modified before the given timestamp(in milliseconds). Example: modifiedBefore:1457997222.
        modifiedAfter : Filter by the content objects modified after the given timestamp(in milliseconds). Example: modifiedAfter:1457997111.
        type : Filter by the type of the content object. Example: type:folder.
        monitorStatus : Filter by the status of the monitor: Normal, Critical, Warning, MissingData, Disabled, AllTriggered. Example: monitorStatus:Normal.
        You can also use multiple filters in one query. For example to search for all content objects created by user with identifier 000000000000968B with creation timestamp after 1457997222 containing the text Test, the query would look like:

        createdBy:000000000000968B createdAfter:1457997222 Test

     .PARAMETER limit
    rows to return max 1000

    .PARAMETER token
    Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results


     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MonitorsSearch {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(Mandatory=$true)][string] $query ,
        [parameter()][string] $limit = 100,
         [parameter()][string] $offset = 0
     )

     $params = @{'limit' = $limit; 'token' = $offset; 'query' = $query }

     return (invoke-sumo -path "monitors/search" -method GET -session $sumo_session -v 'v1' -params $params )
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/usageInfo,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MonitorsUsageInfo {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "monitors/usageInfo" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-MonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "monitors/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MonitorsObjectById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "monitors/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-MonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "monitors/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{id}/copy,post
     Copy a monitor or folder in the monitors library
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER parentid
     id of new parent object

     .PARAMETER name
     optional new name

     .PARAMETER description
     optional new description
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Copy-MonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)][string] $parentid,
         [parameter(mandatory=$false)][string] $name,
         [parameter(mandatory=$false)][string] $description
     )
    $body = @{ "parentId" = $parentid; }
    if ($name) { $body['name'] = $name }
    if ($description) { $body['description'] = $description }

     return (invoke-sumo -path "monitors/$id/copy" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{id}/export,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MonitorExportById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "monitors/$id/export" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{id}/move,post
     move a monitor or folder in the monitors library
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER parentid
     id of new parent object

     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Move-MonitorById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)][string] $parentid
     )
    $body = @{ "parentId" = $parentid; }

     return (invoke-sumo -path "monitors/$id/move" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 
 <#
     .DESCRIPTION
     /v1/monitors/{id}/path,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-MonitorsObjectPathById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "monitors/$id/path" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/monitors/{parentId}/import,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER parentId
     parentId for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-MonitorImportById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$parentId,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "monitors/$parentId/import" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 

######################################################### partitions.ps1 functions ##############################################################
# auto generated by srcgen partitions 11/17/2020 2:22:05 PM 


<#
    .DESCRIPTION
    /v1/partitions,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Partitions {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "partitions" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/partitions,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER name
     The name of the partition.

     .PARAMETER routingExpression
     The query that defines the data to be included in the partition.

     .PARAMETER analyticsTier
     optional: 'frequent','infrequent','continuous','security', default continuous

    .PARAMETER retentionPeriod
    optional int days

    .PARAMETER dataForwardingId
    An optional ID of a data forwarding configuration to be used by the partition.
 
    .PARAMETER dryrun
    boolean - set to true to output the parition definition as JSON rather that post to sumo.

     .OUTPUTS
     PSCustomObject or json (if dryrun)
 #>
 
 
 function New-Partition {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)][string]$name,
         [parameter(mandatory=$True)][string]$routingExpression,
         [parameter(mandatory=$false)][string][ValidateSet('frequent','infrequent','continuous','security')]$analyticsTier = 'continuous',
         [parameter(mandatory=$false)][int]$retentionPeriod,
         [parameter(mandatory=$false)][string]$dataForwardingId,
         [parameter(mandatory=$false)][bool]$dryrun=$false

     )

     $partition = '{  "name": "apache", "routingExpression": "_sourcecategory=*/Apache", "analyticsTier": "continuous" }' | convertfrom-json -depth 10
     $partition.name = $name
     $partition.routingExpression = $routingExpression
     $partition.analyticsTier = $analyticsTier
     if ($retentionPeriod) {
       $partition | Add-Member -NotePropertyName retentionPeriod -NotePropertyValue $retentionPeriod
     }

     if ($dataForwardingId) {
        $partition | Add-Member -NotePropertyName dataForwardingId -NotePropertyValue $dataForwardingId
      }

    # isCompliant is not supported yet as it's a restricted feature.
      if ($dryrun) { return ($partition | convertto-json)} else {

          return (invoke-sumo -path "partitions" -method POST -session $sumo_session -v 'v1' -body $partition )
      }
 }
 
 <#
     .DESCRIPTION
     /v1/partitions/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-PartitionById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "partitions/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/partitions/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-PartitionById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "partitions/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/partitions/{id}/cancelRetentionUpdate,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-PartitionCancelRetentionUpdateById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "partitions/$id/cancelRetentionUpdate" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/partitions/{id}/decommission,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-PartitionDecommissionById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "partitions/$id/decommission" -method POST -session $sumo_session -v 'v1' )
 }
 
 

######################################################### permissions.ps1 functions ##############################################################
<#
    .DESCRIPTION
    /v2/content/{id}/permissions,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>

function Get-ContentPermissionsById {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $false)]$explicitOnly = $false       
    )
    $params = @{'explicitOnly' = $explicitOnly}
    return (invoke-sumo -path "content/$id/permissions" -method GET -session $sumo_session -v 'v2' -params $params)
}
 
<#
     .DESCRIPTION
     /v2/content/{id}/permissions/add,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-ContentPermissionsAddById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "content/$id/permissions/add" -method PUT -session $sumo_session -v 'v2' -body $body )
}
 
<#
     .DESCRIPTION
     /v2/content/{id}/permissions/remove,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-ContentPermissionsRemoveById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "content/$id/permissions/remove" -method PUT -session $sumo_session -v 'v2' -body $body )
}
 

######################################################### roles.ps1 functions ##############################################################
# auto generated by srcgen roles 11/20/2020 9:17:48 AM 


<#
    .DESCRIPTION
    /v1/roles,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Roles {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $limit = 100,
        [parameter()][string] $sortBy,
        [parameter()][string] $name,
        [parameter()][string] $token
         
    )
    $params = @{'limit' = $limit; }

    if ($token) { $params['token'] = $token }
    if ($name) { $params['name'] = $name }
    if ($sortBy) { $params['sortBy'] = $sortBy }

    return (invoke-sumo -path "roles" -method GET -session $sumo_session -v 'v1' -params $params)
}
 
<#
     .DESCRIPTION
     /v1/roles,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function New-Role {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "roles" -method POST -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/roles/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-RoleById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "roles/$id" -method DELETE -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/roles/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-RoleById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "roles/$id" -method GET -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/roles/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-RoleById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "roles/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
}
 
<#
     .DESCRIPTION
     /v1/roles/{roleId}/users/{userId},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER roleId
     roleId for delete
 
     .PARAMETER userId
     userId for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Remove-RoleUserById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$roleId,
        [parameter(mandatory = $True)]$userId
    )
    return (invoke-sumo -path "roles/$roleId/users/$userId" -method DELETE -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/roles/{roleId}/users/{userId},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER roleId
     roleId for put
 
     .PARAMETER userId
     userId for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-RoleUserById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$roleId,
        [parameter(mandatory = $True)]$userId
    )
    return (invoke-sumo -path "roles/$roleId/users/$userId" -method PUT -session $sumo_session -v 'v1'  )
}
 
 

######################################################### saml.ps1 functions ##############################################################

######################################################### scheduledviews.ps1 functions ##############################################################

# /v1/scheduledViews

<#
    .DESCRIPTION
    get /v1/scheduledViews

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-scheduledViews {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "scheduledViews" -session $sumo_session -v 'v1')
}

######################################################### searchjob.ps1 functions ##############################################################
# an alternative to the sumologic powerhshell sdk start-searchjob

Function get-epochDate ($epochDate) { 
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epochDate)) 
}

# note we return 1s 10 digit epoc times (not ms epcotimes)
function sumotime([string]$time) {
    
    if ($time -match 'm') {
        $multiplier = 60 
    } elseif ($time -match 's') {
        $multiplier = 1
    } elseif ($time -match 'h') {
        $multiplier = 60 * 60 
    } elseif ($time -match 'd') {
        $multiplier = 60 * 60 * 24
    } else { Write-Error "invalid sumo timespec must be m s h d (minutes, seconds, hours or days"}
    $t = $time -replace 'h|m|d|s|-',''

    [bigint]$offset = ($t -as [int] ) * $multiplier 
    $now =  [bigint][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s)) 
    return [bigint]($now - $offset)
}
# this function would evaluate sumo time range expressions such as -15m or -1h to -5m
# note we return 1s 10 digit epoc times (not ms epcotimes)
function sumolast($last) {
    $last = $last.tolower()
    If ($last -match '^[^ ]+ [^ ]+$') {
        $f, $t = $last -split ' '
        $from = sumotime($f)
        $to = sumotime($t)
    }
    elseif ($last -match '^-[0-9]+[hmsd]$' ) {
        $from = sumotime($last)
        $to = [int][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s))
    }
    else {
        Write-Error "Sumo last expression failed validation must be -<digit>[hmsd] or -<range><space>-<range> where range is -<digit>[hmsd]"
        return $false, $false
    }
    return $from,$to
}


function epocvalidation ($epoc) {
    if ($epoc.toString() -match '[0-9]{13}' ) {
        return [bigint]($epoc / 1000)
    }
    elseif ($epoc.toString() -match '[0-9]{10}' ) {
        return [bigint]($epoc )
    }
    else {
        write-error "epoc $epoc failed validation"
        return $false
    }
}


<#
.SYNOPSIS
Start a search job

.DESCRIPTION
Start a search job or create schema for a search job with -dryrun
Time can be specified with aboslute epoc for from, to or with last such as -last -5m or -last '-1h -7m'

.PARAMETER Query
The query used for the search in string. You can also use -File

.PARAMETER File
path to a file containing the query (alternative to -query)

.PARAMETER Last
A time span for query recent results. This is same as sumo search UI you can use a single range for a start and end range separated by a space for example:
-5m
-1h -7m

.PARAMETER From
Supply an aboslute epoc start time

.PARAMETER To
Supply an aboslute epoc end time

.PARAMETER TimeZone
Time zone used for time range query defaults to UTC

.PARAMETER dryrun
if set to true function returns the query object that wouuld be submitted as -body

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

.PARAMETER substitutions
an array of substitution hashes for parameterized queries. Each hash should have a replace and with key.
Each sub is replaced in the query text block.
Note the substitution is vs a json-ified version of the query object.
replace: is the regular expression to match the replace text
with: is the string to substitute for the matching pattern.
-substitutions @(@{'replace'='foo';'with'='bar'},@{'replace'='red';'with'='blue'};)

.EXAMPLE
New-SearchQuery -query 'error' -last '-5m' -sumo_session $be 

.OUTPUTS
PSObject for the search job which as id and link properties.

#>
function New-SearchQuery {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][bigint]$from,
        [parameter()][bigint]$to,
        [parameter()][string]$query,   
        [parameter()][string]$file, 
        [parameter()][string]$last,
        [parameter()][string]$timeZone = 'UTC',
        [parameter()][string]$byReceiptTime = 'False',
        [parameter()][string]$autoParsingMode = 'performance',
        [parameter(mandatory = $false)][bool]$dryrun = $false,
        [Parameter(Mandatory = $false)][array]$substitutions


    )

    $utcNow = [bigint][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s)) * 1000

    # we must have a valid query
    if ($query) {
    }
    elseif ($file) {
        $query = Get-Content -Path $file -Raw
    }
    else {
        Write-Error "New-SearchJob requires either -query or -file"
        return $null
    }

    if ($substitutions) {
        Write-Verbose 'activating substitutions'
        $query = batchReplace -in $query -substitutions $substitutions
    }

    if ($last) { 
        $from,$to = sumolast($last)
        if ($from -and $to ) {} else {
            Write-Error "sumo -last value vailed validation"
            return $null
        }

    }
    elseif ($from -and $to ) {
        $from = epocvalidation($from)
        $to = epocvalication($to)
        if ($from -and $to) {
            Write-Verbose "from and to passed validation"
        }
        else {
            Write-Error "-from and -to of $from and $to do not match millisecond epoc time validation."
            return $null
        }
    }
    else {
        Write-Verbose "using default time range -5m"
        $from = $utcNow - (1000 * 60 * 5)
        $to = $utcNow
    }

    # in case it's not ms times which often it might be.
    if ($from -lt 10000000000) {
        $from = $from * 1000
    }

    if ($to -lt 10000000000) {
        $to = $to * 1000
    }

    $body = @{
        "query"    = $query
        "from"     = "$from"
        "to"       = "$to"
        "timeZone" = $timeZone
        "byReceiptTime" = $byReceiptTime
        "autoParsingMode" = $autoParsingMode
    }

    if ($dryrun ) {
        return $body
    } else {
        return (invoke-sumo -path "search/jobs" -method 'POST' -session $sumo_session  -body $body -v 'v1')
    }

}

<#
.SYNOPSIS
Start a search job using a body object, not to be confused with start-searchjob in powershell sdk

.DESCRIPTION
Start a search job with just a compliant body object.

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

.PARAMETER body
search job query body as per api spec, or produced with new-searchjobquery -dryrun $true

.OUTPUTS
PSObject for the search job which as id and link properties.

#>
function New-SearchJob {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)] $body
    )

    return (invoke-sumo -path "search/jobs" -method 'POST' -session $sumo_session  -body $body -v 'v1')
}

<#
.SYNOPSIS
call job status api 

.DESCRIPTION
call job status api for job id

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

.PARAMETER jobid
job id

.OUTPUTS
PSObject for the search job which as id and link properties.

#>
function get-SearchJobStatus {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $jobId

    )
    $j = invoke-sumo -path "search/jobs/$jobId" -method 'GET' -session $sumo_session -v 'v1'
    $j | Add-Member -NotePropertyName id -NotePropertyValue $jobId

    return $j
}

<#
.SYNOPSIS
export the records or messages from an search job that has finished.

.DESCRIPTION
get results of a search job.

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

.PARAMETER job
A job object from a previous search result that has an id property.

.PARAMETER  return
type of result to return in object from records or messages. defaults to records.

.PARAMETER limit
page size to poll results, defaults to 1000

.OUTPUTS
PSObject for the search job which as id and link properties.

#>
function Export-SearchJobEvents {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)] $job, 
        [parameter(Mandatory = $false)][string]  [ValidateSet("records","messages")] $return = "records",
        [parameter(Mandatory = $false)][int] $limit = 1000

    )

        if ($job.id -and ($job.PSobject.Properties.name -match "messageCount") -and ($job.PSobject.Properties.name -match "recordCount") ) {

        } else { 
            Write-Error "passed -job object is missing required properties"
            return @()
    }

    $offset=0

    if ($return -eq "records") {
        $totalresults = $job.recordCount
    } elseif ($return -eq "messages") {
        $totalresults = $job.messageCount
    }
    $remaining = $totalresults
    $resultSet = '{  "fields":[],  "records":[] , "messages": [] }' | ConvertFrom-Json

    While ($totalresults -gt 0 -and $remaining -gt 0) {
        $params = @{
            "offset" = $offset
            "limit" = $limit
        }
        # get the page
        $page =  (invoke-sumo -path "search/jobs/$($job.id)/$return" -method 'GET' -session $sumo_session   -v 'v1' -params $params)

        $resultSet.fields = $page.fields
        $resultSet.$return = $resultSet.$return + $page.$return

        $remaining = $remaining - $offset
        $offset = $offset + $limit
    }

    return $resultSet
}

<#
.SYNOPSIS
wrapper to poll for completion and return results either from a query or exisitng job.

.DESCRIPTION
wrapper to poll for completion and return results either from a query or exisitng job.

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

.PARAMETER query
optional query object from New-SearchQuery -dryrun

.PARAMETER jobid
optional id of an existing job

.PARAMETER job
optional job object with id of exiting job

.PARAMETER poll_secs
default 1, the poll interval to check for job completion.

.PARAMETER max_tries
default 60, the maximumum number of poll cycles to wait for completion

.PARAMETER return
"status","records","messages"
status returns on the job result object
records adds a records property contining the records results pages
messages adds a messages property containing the messages results pages

.OUTPUTS
PSObject for the search job which as id. May have records or messages properties.

#>
function get-SearchJobResult {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $false)] $query, # query object from New-SearchQuery -dryrun
        [parameter(Mandatory = $false)] $jobid, # job id of an existing completed job
        [parameter(Mandatory = $false)] $job, # job object
        [parameter(Mandatory = $false)][int] $poll_secs = 1,
        [parameter(Mandatory = $false)][int] $max_tries = 60,
        [parameter(Mandatory = $false)][string]  [ValidateSet("status","records","messages")] $return = "status"

    )

    if ($jobid) {
        Write-Verbose 'run by job id'

    }  elseif ($job) {
        Write-Verbose 'run by job object'
        if ($job.id) {
            $jobid=$job.id
        } else { 
            Write-Error 'job object has no id property';
            return $job
        }
    }  elseif ($query ) {
        Write-Verbose 'run by query'
        Write-Verbose "query: `n$($query | convertto-json -depth 10) `n"
        $job = New-SearchJob -body $query -sumo_session $sumo_session
        $jobid=$job.id
    } else {
        Write-Error 'you must provide a new -query object or -jobid of an existing job, or a -job object with id.'
    }
    
    $tries = 0
    $last = "none"

    While ($jobid -and ($max_tries -gt $tries)) {
        $tries = $tries + 1     
        Write-Verbose "polling job $jobid. try: $tries of $max_tries"
        
        $job_state = get-SearchJobStatus -jobId $jobid -sumo_session $sumo_session
        if ($last -ne $job_state.state) {
            write-host "change status: from: $last to $($job_state.state) at $($tries * $poll_seconds) seconds."
            $last = "$($job_state.state)"
        } else {
            Write-Verbose  ($job_state.state)
        }

        if ($job_state.state -eq 'DONE GATHERING RESULTS') {
            
            break
        }
        else {
            Start-Sleep -Seconds $poll_secs
        }

        # add the jobid 
        
    }   
    Write-Verbose "job poll completed: status: $($job_state.state) jobId: $jobid"
    if ($job_state.state -ne 'DONE GATHERING RESULTS') {
         Write-Error "Job failed or timed out for job: $jobid"; 
         return 
    }
    $job_state  | Add-Member -NotePropertyName id -NotePropertyValue $jobid -Force

    if ($return -eq "messages" ) {
        $job_state | Add-Member -NotePropertyName messages -NotePropertyValue (Export-SearchJobEvents -job $job_state -return 'messages')
    } elseif ($return -eq "records") {
        $job_state | Add-Member -NotePropertyName records -NotePropertyValue (Export-SearchJobEvents -job $job_state -return 'records')
    }

    return  $job_state
}

######################################################### servicewhitelist.ps1 functions ##############################################################

######################################################### sources.ps1 functions ##############################################################

<#
    .DESCRIPTION
    get /collectors/[collectorId]/sources

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-sources {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)] $id
        
    )
    return (invoke-sumo -path "collectors/$id/sources" -session $sumo_session -v $v )
}



<#
    .DESCRIPTION
    get /collectors/[collectorId]/sources/[sourceId]

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-sourceById {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)] $id,
        [parameter(Mandatory = $true)] $sourceid

        
    )
    return (invoke-sumo -path "collectors/$id/sources/$sourceid" -session $sumo_session -v $v )
}

######################################################### tokens.ps1 functions ##############################################################

######################################################### transformationrules.ps1 functions ##############################################################

######################################################### users.ps1 functions ##############################################################
# auto generated by srcgen users 11/20/2020 9:17:48 AM 


<#
    .DESCRIPTION
    /v1/users,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER limit
    default 100 Limit the number of users returned in the response

    .PARAMETER token
    Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. token is set to null when no more pages are left.

    .PARAMETER sortBy
    Sort the list of users by the firstName, lastName, or email field.

    .OUTPUTS
    PSCustomObject.
#>


function Get-Users {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter()][string] $limit = 100,
         [parameter(mandatory=$false)][string][ValidateSet('firstName','lastName','email')] $sortBy,
         [parameter()][string] $email,
         [parameter()][string] $token
     )
     $params = @{'limit' = $limit; }
     if ($token) { $params['token'] = $token }
     if ($email) { $params['email'] = $email }
     if ($sortBy) { $params['sortBy'] = $sortBy }     
     return (invoke-sumo -path "users" -method GET -session $sumo_session -v 'v1' -params $params)
 }
 
 <#
     .DESCRIPTION
     /v1/users,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-User {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-UserById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-UserById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-UserById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/email/requestChange,post
     An email with an activation link is sent to the user?s new email address. The user must click the link in the email within seven days to complete the email address change, or the link will expire.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-UserEmailRequestChangeById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users/$id/email/requestChange" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/mfa/disable,put
     Disable multi-factor authentication for given user.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-UserMfaDisableById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users/$id/mfa/disable" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/password/reset,post
     Reset a user's password.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Reset-UserPasswordById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id/password/reset" -method POST -session $sumo_session -v 'v1' )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/unlock,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-UserUnlockById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id/unlock" -method POST -session $sumo_session -v 'v1' )
 }
 


######################################################### Export Functions ##############################################################
#Export-ModuleMember -Cmdlet new-ContentSession
#Export-ModuleMember -Function getQueryString
#Export-ModuleMember -Cmdlet invoke-sumo
#Export-ModuleMember -Cmdlet copy-proppy
#Export-ModuleMember -Function convertSumoDecimalContentIdToHexId
#Export-ModuleMember -Cmdlet New-MultipartBoundary
#Export-ModuleMember -Function batchReplace
#Export-ModuleMember -Cmdlet Get-AccessKeys
#Export-ModuleMember -Cmdlet Get-Apps
#Export-ModuleMember -Cmdlet New-AppInstallById
#Export-ModuleMember -Cmdlet Install-SumoApp
#Export-ModuleMember -Cmdlet get-collectors
#Export-ModuleMember -Cmdlet get-offlineCollectors
#Export-ModuleMember -Cmdlet get-collectorById
#Export-ModuleMember -Cmdlet get-collectorByName
#Export-ModuleMember -Cmdlet Get-Connections
#Export-ModuleMember -Cmdlet get-ContentByPath
#Export-ModuleMember -Cmdlet get-ContentPath
#Export-ModuleMember -Cmdlet start-ContentExportJob
#Export-ModuleMember -Cmdlet get-ContentExportJobStatus
#Export-ModuleMember -Cmdlet get-ContentExportJobResult
#Export-ModuleMember -Cmdlet get-ExportContent
#Export-ModuleMember -Cmdlet start-ContentCopyJob
#Export-ModuleMember -Cmdlet get-ContentCopyJobStatus
#Export-ModuleMember -Cmdlet start-ContentImportJob
#Export-ModuleMember -Cmdlet Get-ContentFoldersImportStatusById
#Export-ModuleMember -Cmdlet Move-ContentById
#Export-ModuleMember -Cmdlet Get-ContentFolderById
#Export-ModuleMember -Cmdlet Set-ContentFoldersById
#Export-ModuleMember -Cmdlet New-Dashboard
#Export-ModuleMember -Cmdlet Get-DashboardContentIdById
#Export-ModuleMember -Cmdlet Get-ExtractionRules
#Export-ModuleMember -Cmdlet Get-Fields
#Export-ModuleMember -Cmdlet get-Folder
#Export-ModuleMember -Cmdlet get-PersonalFolder
#Export-ModuleMember -Cmdlet get-GlobalFolder
#Export-ModuleMember -Cmdlet get-adminRecommended
#Export-ModuleMember -Cmdlet get-folderJobStatus
#Export-ModuleMember -Cmdlet get-folderJobResult
#Export-ModuleMember -Cmdlet get-folderContent
#Export-ModuleMember -Cmdlet new-folder
#Export-ModuleMember -Cmdlet Get-HealthEvents
#Export-ModuleMember -Cmdlet Get-HealthEventResources
#Export-ModuleMember -Cmdlet Get-IngestBudgetsv1
#Export-ModuleMember -Cmdlet New-IngestBudgetsv1
#Export-ModuleMember -Cmdlet Remove-IngestBudgetv1ById
#Export-ModuleMember -Cmdlet Get-IngestBudgetv1ById
#Export-ModuleMember -Cmdlet Set-IngestBudgetv1ById
#Export-ModuleMember -Cmdlet Get-IngestBudgetv1CollectorsById
#Export-ModuleMember -Cmdlet Remove-IngestBudgetv1CollectorsById
#Export-ModuleMember -Cmdlet Set-IngestBudgetv1CollectorsById
#Export-ModuleMember -Cmdlet Reset-IngestBudgetv1UsageResetById
#Export-ModuleMember -Cmdlet Get-IngestBudgetsv2
#Export-ModuleMember -Cmdlet New-IngestBudgetsv2
#Export-ModuleMember -Cmdlet Remove-IngestBudgetv2ById
#Export-ModuleMember -Cmdlet Get-IngestBudgetv2ById
#Export-ModuleMember -Cmdlet Set-IngestBudgetv2ById
#Export-ModuleMember -Cmdlet Reset-IngestBudgetv2UsageResetById
#Export-ModuleMember -Cmdlet Get-LogSearchesEstimatedUsage
#Export-ModuleMember -Cmdlet New-LookupTable
#Export-ModuleMember -Cmdlet Get-LookupTableJobsStatusById
#Export-ModuleMember -Cmdlet Remove-LookupTableById
#Export-ModuleMember -Cmdlet Get-LookupTableById
#Export-ModuleMember -Cmdlet Set-LookupTableById
#Export-ModuleMember -Cmdlet Remove-LookupTableRowById
#Export-ModuleMember -Cmdlet New-LookupTableRowById
#Export-ModuleMember -Cmdlet New-LookupTableTruncateById
#Export-ModuleMember -Cmdlet Set-LookupTableFromCsv
#Export-ModuleMember -Cmdlet Get-MetricsAlertMonitors
#Export-ModuleMember -Cmdlet New-MetricsSearch
#Export-ModuleMember -Cmdlet Get-Partitions
#Export-ModuleMember -Cmdlet Get-ContentPermissionsById
#Export-ModuleMember -Cmdlet Set-ContentPermissionsAddById
#Export-ModuleMember -Cmdlet Set-ContentPermissionsRemoveById
#Export-ModuleMember -Cmdlet Get-Roles
#Export-ModuleMember -Cmdlet New-Role
#Export-ModuleMember -Cmdlet Remove-RoleById
#Export-ModuleMember -Cmdlet Get-RoleById
#Export-ModuleMember -Cmdlet Set-RoleById
#Export-ModuleMember -Cmdlet Remove-RoleUserById
#Export-ModuleMember -Cmdlet Set-RoleUserById
#Export-ModuleMember -Cmdlet get-scheduledViews
#Export-ModuleMember -Cmdlet get-epochDate 
#Export-ModuleMember -Function sumotime
#Export-ModuleMember -Function sumolast
#Export-ModuleMember -Function epocvalidation 
#Export-ModuleMember -Cmdlet New-SearchQuery
#Export-ModuleMember -Cmdlet New-SearchJob
#Export-ModuleMember -Cmdlet get-SearchJobStatus
#Export-ModuleMember -Cmdlet Export-SearchJobEvents
#Export-ModuleMember -Cmdlet get-SearchJobResult
#Export-ModuleMember -Cmdlet get-sources
#Export-ModuleMember -Cmdlet get-sourceById
#Export-ModuleMember -Cmdlet Get-Users
