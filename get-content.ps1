# powershell functions to export content, and put into terraform format (useful for prototyping content or migration)

<#
    .SYNOPSIS
        Powershell functions to export content from sumologic content and folder apis. https://api.sumologic.com/docs/#tag/contentManagement
 
    .DESCRIPTION
        Powershell wrapper to get, export or import content from Sumo Logic Library.
#>

Param(
        [parameter(Mandatory=$false)][string] $Parent = "Personal",
        [parameter(Mandatory=$false)][string] $endpoint="https://api.us2.sumologic.com",
        [parameter(Mandatory=$false)][string] $accessid=$env:SUMO_ACCESS_ID_BE,
        [parameter(Mandatory=$false)][string] $accesskey=$env:SUMO_ACCESS_KEY_BE,
        [switch]$isAdminMode
)

$Credential = New-Object System.Management.Automation.PSCredential $accessid, ($accesskey | ConvertTo-SecureString -AsPlainText -Force )

if ($IsAdminMode) { $mode = $True}  else { $mode = $False}

<#
    .DESCRIPTION
    Wrapper to make calls to Sumo Logic API
        
    .SYNOPSIS
        
    .EXAMPLE
        invoke-sumo [-path] <String> [[-method] <String>] [[-sumo_endpoint] <String>] [[-params] <Hashtable>] [<CommonParameters>]
        
    .PARAMETER path
    Path to be appended to 'https://endpoint/api/v2'

    .PARAMETER sumo_endpoint
    API endpoint such as https://api.us2.sumologic.com

    .PARAMETER method
    HTTP method default GET

    .PARAMETER params
    hashtable of POST params (optional)

#>
function invoke-sumo {
    param(
        [parameter(Mandatory)][string] $path,
        [parameter()][string] $method = 'GET',
        [parameter()][string] $sumo_endpoint=$endpoint,
        [parameter()][Hashtable] $params
    )
    $uri = (@($sumo_endpoint,'api/v2',$path) -join "/") -replace '//v2','/v2'
    write-verbose "invoke_sumo $uri $method"
    if (($params ) -or ( $mode )) {
        $params['isAdminMode'] = $mode.toString().tolower()
        $r = (Invoke-WebRequest -Uri $uri -method $method -Credential $Credential -SessionVariable webSession -Body $params).Content | convertfrom-json

    } else {
        $r = (Invoke-WebRequest -Uri $uri -method $method -Credential $Credential -SessionVariable webSession).Content | convertfrom-json
    }
    return $r
}

<#
    .DESCRIPTION
    get personal folder as an object.
#>

function get-PersonalFolder {
    return invoke-sumo -path "content/folders/personal"
}


<#
    .DESCRIPTION
    get /v2/content/folders/{id}

    .PARAMETER id
    content id

#>

function get-Folder {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return invoke-sumo -path "content/folders/$id"
}

<#
    .DESCRIPTION
    get content item using path

    .PARAMETER path
    content path

#>
function get-ContentByPath {
    Param(
        [parameter(Mandatory=$true)][string] $path 
)
    return invoke-sumo -path "content/path" -params @{ 'path' = $path;}
}

<#
    .DESCRIPTION
    get path of an item using id

    .PARAMETER id
    content id
#>
function get-ContentPath {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return (invoke-sumo -path "content/$id/path").path
}

<#
    .DESCRIPTION
    Start a content export job using content id

    .PARAMETER id
    content id
#>
function start-ContentExportJob {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return @{'contentId' = $id; 'jobId' = (invoke-sumo -path "content/$id/export/" -method 'POST').id }
}

<#
    .DESCRIPTION
    Get status of a content export job

    .PARAMETER id
    content id

    .PARAMETER job
    export job id
    #>
function get-ContentExportJobStatus {
    Param(
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

)
    return invoke-sumo -path "content/$id/export/$job/status" -method 'GET'
}

<#
    .DESCRIPTION
    Get generated output of a completed export job.

    .PARAMETER id
    content id

    .PARAMETER job
    export job id
#>
function get-ContentExportJobResult {
    Param(
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

)
    return invoke-sumo -path "content/$id/export/$job/result" -method 'GET'
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
#>
function run-ContentExportJob {
    Param(
        [parameter(Mandatory=$true)][string] $id ,
        [parameter(Mandatory=$false)][string] $poll_secs=1,
        [parameter(Mandatory=$false)][string] $max_tries=15
)
    $job = start-ContentExportJob -id $id
    $tries = 0

    While  (($job) -and ($max_tries -gt $tries)) {
        $tries = $tries +1     
        Write-Verbose "polling id: $id $($job['jobId']). try: $tries of $max_tries"
        $job_state = get-ContentExportJobStatus -job $job['jobId'] -id $id
        Write-Verbose  ($job_state.status)
        if ($job_state.status -eq 'Success') {
            
             break
        } else {
            Start-Sleep -Seconds $poll_secs
        }
    }   
    Write-Verbose "job poll completed: status: $($job_state.status) contentId: $id jobId: $($job['jobId'])"
    if ($job_state.status -eq 'Success') {
        $result = get-ContentExportJobResult -job $job['jobId'] -id $id
    } else { Write-Error 'Job failed or timed out';}
    return  $result
}



##########################  example code #########################################
if ($Parent -eq "Personal") {
    $parent_folder = get-PersonalFolder
} else {
    write-host "exporting only implemented for personal folder. please come back later once this is built!"
    exit
}

# locate content by parent folder and name
$FolderNameToExport = "Search Audit Custom"
$export_id =  ($parent_folder.children | where {$_.ItemType -eq "Folder" -and $_.name -eq $FolderNameToExport}).id
$export_item_path = get-ContentPath -id $export_id
$item_by_path = get-ContentByPath -path $export_item_path

# only this version icludes children via folder api
$child_item = get-Folder -id $export_id
$export_item = run-ContentExportJob -id $export_id

# beware default depth is too small for most nested content
#(run-ContentExportJob -id $export_id ) |convertto-json -Depth 100