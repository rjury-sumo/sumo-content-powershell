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
        [parameter(Mandatory = $false)][string] $endpoint = $env:SUMOLOGIC_API_ENDPOINT,
        [parameter(Mandatory = $false)][string] $accessid = $env:SUMO_ACCESS_ID,
        [parameter(Mandatory = $false)][string] $accesskey = $env:SUMO_ACCESS_KEY,
        [parameter(Mandatory = $false)][string] $name = $accessid,
        [parameter(Mandatory = $false)][ValidateSet('true', 'false')][string] $isAdminMode = "false"

    )
    $Credential = New-Object System.Management.Automation.PSCredential $accessid, ($accesskey | ConvertTo-SecureString -AsPlainText -Force )

    # default endpoint
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
        [parameter()][string] $body,
        [parameter()][string] $v = "v2"
    )

    if ($session -and $session.endpoint) { 
        $headers = @{
            "content-type" = "application/json";
            "accept"       = "application/json";
            "isAdminMode"  = $session.isAdminMode
        }

        $uri = (@($session.endpoint, "api/$v", $path) -join "/") -replace '//v', '/v'
        write-verbose "session: $($session.name) invoke_sumo $uri $method"
        if ($params) {
            $qStr = getQueryString($params)
            $uri += "?" + $qStr
        }
        if ($body) {
            $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers -Body $body).Content | convertfrom-json
    
        }
        else {
            $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $session.WebSession -Headers $headers  ).Content | convertfrom-json
        }
    }
    else {
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
    if ($type -eq 'global') { return $result.data } else { return $result }
}

<#
    .DESCRIPTION
    get /v2/content/folders/adminRecommended

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
    
    return invoke-sumo -path "content/folders" -method 'POST' -session $sumo_session -Body ($body | ConvertTo-Json) 

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
        [parameter(Mandatory = $false)][string] $overwrite = $false

    )
    return @{'folderId' = $id; 'jobId' = (invoke-sumo -path "content/folders/$folderId/import" -method 'POST' -session $sumo_session -Body $contentJSON -params @{ 'overwrite' = $overwrite ; }).id } 
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
        [parameter(Mandatory = $true)][string] $jobId,
        [parameter(Mandatory = $true)][string] $folderId

    )
    return invoke-sumo -path "content/$folderId/import/$jobId/status" -method 'GET' -session $sumo_session
}


<#
    .DESCRIPTION
    get /v1/fields

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-Fields {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "fields" -session $sumo_session -v 'v1').data
}

<#
    .DESCRIPTION
    get /v1/partitions

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-Partitions {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "partitions" -session $sumo_session -v 'v1').data
}


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
    return (invoke-sumo -path "scheduledViews" -session $sumo_session -v 'v1').data
}

<#
    .DESCRIPTION
    get /v1/roles

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-roles {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "roles" -session $sumo_session -v 'v1').data
}

<#
    .DESCRIPTION
    get /v1/users

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-users {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "users" -session $sumo_session -v 'v1').data
}


<#
    .DESCRIPTION
    get /v1/healthEvents

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-healthEvents {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "healthEvents" -session $sumo_session -v 'v1').data
}

<#
    .DESCRIPTION
    get /v1/ingestBudgets

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-ingestBudgets {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v2"
        
    )
    return (invoke-sumo -path "ingestBudgets" -session $sumo_session -v $v).data
}

<#
    .DESCRIPTION
    get /v1/apps

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-apps {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "apps" -session $sumo_session -v $v).data
}

<#
    .DESCRIPTION
    get /v1/lookupTables

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-lookupTables {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "lookupTables" -session $sumo_session -v $v).data
}

<#
    .DESCRIPTION
    get /v1/connections

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-connections {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "connections" -session $sumo_session -v $v).data
}

<#
    .DESCRIPTION
    get /v1/extractionRules

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-extractionRules {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "extractionRules" -session $sumo_session -v $v).data
}


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
    return (invoke-sumo -path "collectors" -session $sumo_session -v $v -params @{'limit' = $limit; 'offset' = $offset }).collectors
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
    return (invoke-sumo -path "collectors/name/$encodedName/" -session $sumo_session -v $v ).collector
}


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
    return (invoke-sumo -path "collectors/$id/sources" -session $sumo_session -v $v ).sources
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
    return (invoke-sumo -path "collectors/$id/sources/$sourceid" -session $sumo_session -v $v ).source
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

    if ($replace_pattern -and $with ) {
        $out = ($to | ConvertTo-Json -Depth 10) -replace $replace_pattern, $with | ConvertFrom-Json -Depth 10

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
