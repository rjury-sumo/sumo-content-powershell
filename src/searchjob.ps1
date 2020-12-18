# an alternative to the sumologic powerhshell sdk start-searchjob

Function get-epochDate ($epochDate) { [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epochDate)) }


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

.EXAMPLE
New-SearchJobQuery -query 'error' -last '-5m' -sumo_session $be 

.OUTPUTS
PSObject for the search job which as id and link properties.

#>
function New-SearchJobQuery {
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
        [parameter(mandatory = $false)][bool]$dryrun = $false

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
Start a search job, not to be confused with start-searchjob in powershell sdk

.DESCRIPTION
Start a search job with just a compliant body object.

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

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

function get-SearchJobStatus {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $jobId

    )
    return invoke-sumo -path "search/jobs/$jobId" -method 'GET' -session $sumo_session -v 'v1'
}


function Export-SearchJobEvents {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)] $job, 
        [parameter(Mandatory = $false)][string]  [ValidateSet("records","messages")] $return = "records",
        [parameter(Mandatory = $false)][int] $limit = 1000

    )

        if ($job.jobid -and ($job.PSobject.Properties.name -match "messageCount") -and ($job.PSobject.Properties.name -match "recordCount") ) {

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
        $page =  (invoke-sumo -path "search/jobs/$($job.jobid)/$return" -method 'GET' -session $sumo_session   -v 'v1' -params $params)

        $resultSet.fields = $page.fields
        $resultSet.$return = $resultSet.$return + $page.$return

        $remaining = $remaining - $offset
        $offset = $offset + $limit
    }

    return $resultSet
}

function get-SearchJobResult {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $false)] $query, # query object from New-SearchQuery -dryrun
        [parameter(Mandatory = $false)] $jobid, # query object from New-SearchQuery -dryrun
        [parameter(Mandatory = $false)][int] $poll_secs = 1,
        [parameter(Mandatory = $false)][int] $max_tries = 60,
        [parameter(Mandatory = $false)][string]  [ValidateSet("status","records","messages")] $return = "status"

    )

    if ($jobid) {
        Write-Verbose 'run by job id'

    }  elseif ($query ) {
        Write-Verbose 'run by query'
        Write-Verbose "query: `n$($query | convertto-json -depth 10) `n"
        $job = New-SearchJob -body $query -sumo_session $sumo_session
        $jobid=$job.id
    } else {
        Write-Error 'you must provide a new -query object or -jobid of an existing job.'
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
    $job_state  | Add-Member -NotePropertyName jobId -NotePropertyValue $jobid

    if ($return -eq "messages" ) {
        $job_state | Add-Member -NotePropertyName results -NotePropertyValue (Export-SearchJobEvents -job $job_state -return 'messages')
    } elseif ($return -eq "records") {
        $job_state | Add-Member -NotePropertyName results -NotePropertyValue (Export-SearchJobEvents -job $job_state -return 'records')
    }

    return  $job_state
}
