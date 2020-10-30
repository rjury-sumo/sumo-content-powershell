
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

