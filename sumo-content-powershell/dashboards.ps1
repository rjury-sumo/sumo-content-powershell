

<#
    .DESCRIPTION
    v2/dashboards

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Dashboards {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter()][string] $limit = 100
     )
     return (invoke-sumo -path "dashboards" -method GET -session $sumo_session -v 'v2' -params @{'limit' = $limit} -keyName 'dashboards' )
 }

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
        [parameter(mandatory = $True)]$body
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
        [parameter(mandatory = $True)]$id
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
        [parameter(mandatory = $True)]$id
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
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
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
        [parameter(mandatory = $True)]$id
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
        [parameter(mandatory = $True)]$dashboard,
        [parameter(mandatory = $True)][string]$pattern,
        [parameter(mandatory = $True)][string]$replacewith

    )

    if ($dashboard.panels) {

        # make a fresh dashboard so we don't trash the origional one in memory.
        $newdash = $dashboard | convertto-json -depth 100 | ConvertFrom-Json -Depth 100

        $p = -1
        foreach ($panel in $dashboard.panels) {
            $p = $p + 1
            $q = -1
            $changes = 0
            foreach ($query in $panel.queries) {
                $q = $q + 1
                $query_instance = $query.queryString
                if ($query_instance -match $pattern) {
                    Write-Verbose "matching panel: $p, query $q replacement: $pattern in $query_instance`n"
                    $changes = $changes + 1
                    $newdash.panels[$p].queries[$q].queryString = $query_instance -replace $pattern, $replacewith
                }
            }
        }
        Write-Verbose "made $changes changes in $($p + 1) panels in $($q +1 ) queries found."
        return $newdash 
    }
    else {
        Write-Error "Dashboard is invalid must be a dashboard object with panels attribute."
    }
}

<#
    .DESCRIPTION
    /v2/dashboards/reportJobs,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-DashboardReportJob {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "dashboards/reportJobs" -method POST -session $sumo_session -v 'v2' -body $body )
}
 
<#
     .DESCRIPTION
     /v2/dashboards/reportJobs/{jobId}/result,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER jobId
     jobId for get

     .PARAMETER filepath
     FilePath - path to save output files. defaults to local dir/exports
 
     .PARAMETER writefile
     boolean defaults true. if false will return object but not write an export file.

     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-DashboardReportJobsResultById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$jobId,
        [parameter()][string] $filepath,
        [parameter()][string] $format = 'Pdf',
        [parameter()][bool]$writefile = $true 
    )

    if ($filepath) {
        # we have a filepath already
    }
    else {
        $filepath = $scriptDir
        new-item -ItemType Directory "$filepath/exports" -ErrorAction SilentlyContinue | Out-Null
        $filepath = "$filepath/exports"
    }

    $filename = "$filepath/$jobid.$($format.tolower())"
    $result = invoke-sumo -path "dashboards/reportJobs/$jobId/result" -method GET -session $sumo_session -v 'v2' -returnResponse 1 #-filepath $filename

    $job_output = @{
        'id'          = $jobId;
        'type'        = $result.Headers["Content-Type"][0];
        'content'     = $result.Content;
        'http_status' = $result.StatusCode;
        'filepath'    = $filename
    }
    if ($writefile) {
        Write-Verbose "writing output file $filename"
        [System.IO.File]::WriteAllBytes("$filename", $result.Content)
    }

    return $job_output
}

<#
     .DESCRIPTION
     /v2/dashboards/reportJobs/{jobId}/status,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER jobId
     jobId for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-DashboardReportJobsStatusById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$jobId
    )
    return (invoke-sumo -path "dashboards/reportJobs/$jobId/status" -method GET -session $sumo_session -v 'v2')
}
 
<#
    .DESCRIPTION
    creates an asynchronous job to generate a report from a template, polls for completion and exports a file

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER format
    pdf or png

    .PARAMETER filepath
    optional file path defaults to ./export

    .PARAMETER timezone
    see tz list as per https://api.au.sumologic.com/docs/#operation/generateDashboardReport

    .PARAMETER templateType
    only DashboardTemplate is implemented at this point

    .PARAMETER id
    the dashboard template id as per the UI address bar.

    .PARAMETER writefile
     boolean defaults true. if false will return object but not write an export file.
    
    .PARAMETER maxTries
    number of polling attempts before timeout

    .PARAMETER pollSeconds
    sleep time between polling attempts

    .OUTPUTS
    PSCustomObject.
#>

function Export-DashboardReport {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $filepath,
        [parameter()][string] $exportFormat = 'Pdf',
        [parameter()][string] $timezone = "America/Los_Angeles",
        [parameter()][string] $templateType = 'DashboardTemplate',
        [parameter(mandatory = $True)][string] $id,
        [parameter()][bool]$writefile = $true ,
        [parameter()]$maxTries = 60,
        [parameter()]$pollSeconds = 1

    )

    if ($templateType -eq 'DashboardTemplate') {
        $exportbody = '{"action":{"actionType":"DirectDownloadReportAction"},"exportFormat":"Pdf","timezone":"America/Los_Angeles","template":{"templateType":"DashboardTemplate"}}' | convertfrom-json -depth 10
        $exportbody.exportFormat = $exportFormat
        $exportbody.timezone = $timezone
        $exportbody.template.templateType = $templateType
        $exportbody.template | Add-Member -NotePropertyName id -NotePropertyValue $id
    }
    
    $exportJob = New-DashboardReportJob -body $exportbody -sumo_session $sumo_session #-verbose
    if ($exportjob.id) {
        $jobid = $exportjob.id
    }
    else {
        write-error "Failed to get a valid dashboard report id"
        return @()
    }
    
    write-verbose "export: $jobid "
    $exportstatus = Get-DashboardReportJobsStatusById -jobid $jobid -sumo_session $sumo_session #-verbose

    Write-verbose "status: $($exportstatus | out-string)"

    $tries = 1
    $last = "none"
    
    While ($jobid -and ($maxTries -gt $tries)) {
        $tries = $tries + 1     
        Write-Verbose "polling export job $jobid try: $tries of $maxTries"
        
        try {
            $job_state = Get-DashboardReportJobsStatusById -jobid $jobid -sumo_session $sumo_session
            if ($last -ne $job_state.status) {
                Write-Verbose "change status: from: $last to $($job_state.status) at $($tries * $pollSeconds) seconds."
                $last = "$($job_state.status)"
            }
            else {
                Write-Verbose  ($job_state.status)
            }
            
            if ($job_state.status -eq 'Success') {
                write-verbose "job: $jobid $($job_state.status) after $($tries * $pollSeconds) seconds."
                break
            }
            else {
                Start-Sleep -Seconds $pollSeconds
            }
        }
        catch {
            Write-Error "Job status poll error: $jobid `n $($job_state | out-string)"
            Write-Error $_.ScriptStackTrace
        }
    }   
    Write-Verbose "job poll completed: status: $($job_state.status) jobId: $jobid"
    if ($job_state.status -ne 'Success') {
        Write-Error "Job failed or timed out for job: $jobid `n $($job_state | out-string) after $($tries * $pollSeconds) seconds." -ErrorAction Stop; 
        return 
    }
    else {
        Write-Verbose "export job $jobid is: ($job_state.status) after $($tries * $pollSeconds) seconds)"
    }
    
    $export_result = Get-DashboardReportJobsResultById -jobid $jobid -sumo_session $sumo_session -format $exportFormat
    $export_result.http_status | Should -Be 200
    write-verbose "exported: $($export_result.filepath)"

    return $export_result
    
}
