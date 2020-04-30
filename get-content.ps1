# powershell functions to export content, and put into terraform format (useful for prototyping content or migration)
Param(
        [parameter(Mandatory=$false)][string] $Parent = "Personal",
        [parameter(Mandatory=$false)][string] $endpoint="https://api.us2.sumologic.com",
        [parameter(Mandatory=$false)][string] $accessid=$env:SUMO_ACCESS_ID_BE,
        [parameter(Mandatory=$false)][string] $accesskey=$env:SUMO_ACCESS_KEY_BE,
        [switch]$isAdminMode
)

$Credential = New-Object System.Management.Automation.PSCredential $accessid, ($accesskey | ConvertTo-SecureString -AsPlainText -Force )

if ($IsAdminMode) { $mode = $True}  else { $mode = $False}

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

# get personal folder as an object
# most useful bits would be id and children array.
function get-PersonalFolder {
    return invoke-sumo -path "content/folders/personal"
}

# get /v2/content/folders/{id}
function get-Folder {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return invoke-sumo -path "content/folders/$id"
}

function get-ContentByPath {
    Param(
        [parameter(Mandatory=$true)][string] $path 
)
    return invoke-sumo -path "content/path" -params @{ 'path' = $path;}
}

# Get path of an item.
function get-ContentPath {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return (invoke-sumo -path "content/$id/path").path
}

function start-ContentExportJob {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return @{'contentId' = $id; 'jobId' = (invoke-sumo -path "content/$id/export/" -method 'POST').id }
}


function get-ContentExportJobStatus {
    Param(
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

)
    return invoke-sumo -path "content/$id/export/$job/status" -method 'GET'
}

function get-ContentExportJobResult {
    Param(
        [parameter(Mandatory=$true)][string] $job,
        [parameter(Mandatory=$true)][string] $id

)
    return invoke-sumo -path "content/$id/export/$job/result" -method 'GET'
}

function run-ContentExportJob {
    Param(
        [parameter(Mandatory=$true)][string] $id ,
        [parameter(Mandatory=$false)][string] $poll_secs=1,
        [parameter(Mandatory=$false)][string] $max_tries=10
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