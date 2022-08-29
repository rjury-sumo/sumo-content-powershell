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
