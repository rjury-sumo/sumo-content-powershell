# powershell functions to export content, and put into terraform format (useful for prototyping content or migration)

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

Add-Type -TypeDefinition @"
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
        [parameter(Mandatory=$false)][string] $endpoint=$env:SUMOLOGIC_API_ENDPOINT,
        [parameter(Mandatory=$false)][string] $accessid=$env:SUMO_ACCESS_ID,
        [parameter(Mandatory=$false)][string] $accesskey=$env:SUMO_ACCESS_KEY,
        [parameter(Mandatory=$false)][string] $name=$accessid,
        [parameter()][bool] $isAdminMode = $false

    )
    $Credential = New-Object System.Management.Automation.PSCredential $accessid, ($accesskey | ConvertTo-SecureString -AsPlainText -Force )

    # default endpoint
    if ($endpoint) { } else { $endpoint = "https://api.us2.sumologic.com"}
        $endpoint = $endpoint -replace "\/$",""
        if ($endpoint -notmatch "^https://api.[a-z0-9\.]+\.sumologic.com$") {
            Write-Error "endpoint: $endpoint must be a valid API endpoint: not match ^https://api.[a-z0-9\.]+\.sumologic.com$"
            #exit 1
        }
        $uri = (@($endpoint,'api/v2','content/folders/personal') -join "/") -replace '//v2','/v2'
        Write-Verbose "establish session to: $uri for $accessid"
        $res = Invoke-WebRequest -Uri $uri -method Get -Credential $Credential -SessionVariable webSession
        if ($res) {
            # export the default session object to shell
            $Script:sumo_session = [SumoAPISession]::new($endpoint, $webSession,$name,$isAdminMode)
          return $sumo_session
        } else { Write-Error "session failed." ; 
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
        [parameter()][string] $body
    )

    if ($session -and $session.endpoint) { 
        $headers = @{
            "content-type" = "application/json";
            "accept"       = "application/json";
            "isAdminMode" = $session.isAdminMode
          }

        $uri = (@($session.endpoint,'api/v2',$path) -join "/") -replace '//v2','/v2'
        write-verbose "session: $($session.name) invoke_sumo $uri $method"
        if ($params) {
            $qStr = getQueryString($params)
            $uri += "?" + $qStr
        }
        if ($body) {
            $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -Body $body).Content | convertfrom-json
    
        } else {
            $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers  ).Content | convertfrom-json
        }
    } else {
        Write-Error "you must supply a valid session object to invoke-sumo"
    }
  return $r
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
        [parameter(Mandatory=$true)][string] $id 
        
)
    return invoke-sumo -path "content/folders/$id" -session $sumo_session
}


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
        [parameter(Mandatory=$true)][string] $path 
)
    return invoke-sumo -path "content/path" -params @{ 'path' = $path;} -session $sumo_session
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
        [parameter(Mandatory=$true)][string] $id 
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
        [parameter(Mandatory=$true)][string] $id 
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
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

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
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

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
        [parameter(Mandatory=$true)][string] $id ,
        [parameter(Mandatory=$false)][string] $poll_secs=1,
        [parameter(Mandatory=$false)][string] $max_tries=15
)
    $job = start-ContentExportJob -id $id -sumo_session $sumo_session
    $tries = 0

    While  (($job) -and ($max_tries -gt $tries)) {
        $tries = $tries +1     
        Write-Verbose "polling id: $id $($job['jobId']). try: $tries of $max_tries"
        $job_state = get-ContentExportJobStatus -job $job['jobId'] -id $id -sumo_session $sumo_session
        Write-Verbose  ($job_state.status)
        if ($job_state.status -eq 'Success') {
            
             break
        } else {
            Start-Sleep -Seconds $poll_secs
        }
    }   
    Write-Verbose "job poll completed: status: $($job_state.status) contentId: $id jobId: $($job['jobId'])"
    if ($job_state.status -eq 'Success') {
        $result = get-ContentExportJobResult -job $job['jobId'] -id $id -sumo_session $sumo_session
    } else { Write-Error 'Job failed or timed out';}
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
        [parameter(Mandatory=$true)][string] $id ,
        [parameter(Mandatory=$true)][string] $destinationFolder 
)
    return @{'contentId' = $id; 
    'jobId' = (invoke-sumo -path "content/$id/copy" -method 'POST' -session $sumo_session  -params @{ 'destinationFolder' = $destinationFolder;}).id ; 
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
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

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
        [parameter(Mandatory=$true)][string] $folderId ,
        [parameter(Mandatory=$true)] $contentJSON ,
        [parameter(Mandatory=$false)][string] $overwrite = $false

)
    return @{'folderId' = $id; 'jobId' = (invoke-sumo -path "content/folders/$folderId/import" -method 'POST' -session $sumo_session -Body $contentJSON -params @{ 'overwrite' = $overwrite ;}).id  } 
}

<#
    .DESCRIPTION
    Get status of a content import job

    .PARAMETER folderId
    content id

    .PARAMETER jobId
    import job id

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .EXAMPLE
    get-contentimportJobStatus -jobId '4EA1C8F29371B157' -folderId '0000000000AB8526'

    .OUTPUTS
    PSCustomObject. Job status, including 'status' field

#>
function get-ContentimportJobStatus {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory=$true)][string] $jobId,
        [parameter(Mandatory=$true)][string] $folderId

)
    return invoke-sumo -path "content/$folderId/import/$jobId/status" -method 'GET' -session $sumo_session
}
