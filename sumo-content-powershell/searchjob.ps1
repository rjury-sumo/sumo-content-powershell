# an alternative to the sumologic powerhshell sdk start-searchjob

<#
.SYNOPSIS
returns an epch time in ms or not from a date string provided.

.PARAMETER epochDate
Optinoal date, if not provided returns now

.PARAMETER format
can be auto in which case powershell tries default casting or a foramt string for ParseExact.

.OUTPUTS
bigint object as a ms or non ms ecoch time.

#>

Function get-epochDate () { 
    Param(
        [parameter(Mandatory = $false)][string] $epochDate,
        [parameter(Mandatory = $false)][string] $format = 'auto', # or say 'MM/dd/yyyy HH:mm:ss',
        [parameter(Mandatory = $false)][bool] $ms = $true

    )
    if($epochDate) {
        try { 
            if($format -eq 'auto') {
                $date = [datetime]$epochDate
            } else {
                $date = [Datetime]::ParseExact($epochDate, $format, $null)
            }
            $dateUTC = $date.ToUniversalTime()
            [bigint]$epoch = Get-Date $dateUTC -UFormat %s
         }
        catch {
            Write-Host "An error occurred parsing $epochDate using format string: $format"
            Write-Host $_.ScriptStackTrace
        }
    } else {
        $epoch = [int][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s))
    }
    if ($ms) { $epoch = $epoch * 1000}
    return $epoch
}

# return a date string represenation of a epochtime
Function get-DateStringFromEpoch ($epoch) 
{ 
    if ($epoch.toString() -match '[0-9]{13,14}' ) {
        $epoch = [bigint]($epoch / 1000)
    }
    return [string][timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epoch)) 
}

# an alternative to the sumologic powerhshell sdk start-searchjob

<#
.SYNOPSIS
Returns an array of start and end times. ideally to run a query on.

.PARAMETER start
Optinoal date, if not provided returns now

.PARAMETER end
can be auto in which case powershell tries default casting or a foramt string for ParseExact.

.PARAMETER interval_ms
an interval for timeslices expressessed as ms. default is 1 hour

.OUTPUTS
bigint object as a ms or non ms ecoch time.

#>

Function get-timeslices () { 
    Param(
        [parameter(Mandatory = $true)] $start,
        [parameter(Mandatory = $true)] $end,
        [parameter(Mandatory = $false)] $interval_ms = (1000 * 60 * 60)
    )

   $startEpocUtc = get-epochDate -epochDate $start
   $endEpochUtc = get-epochDate -epochDate $end

   $slices = @()
   $remaining = $endEpochUtc - $startEpocUtc
   $s = $startEpocUtc
   Write-Verbose "$start $startEpocUtc $end $endEpochUtc $s $remaining"

   while ($remaining -gt 0) {
       $e = $s + $interval_ms

       if ($e > $endEpochUtc) { 
           $e = $endEpochUtc;
           $interval_ms = $endEpochUtc - $s
       } else {
           $e = $s + $interval_ms
       }

        $slices = $slices + @{ 
            'start' = $s; 
            'end' = $e; 
            'interval_ms' = $interval_ms; 
            "startString" = get-DateStringFromEpoch -epoch $s; 
            "endString" = get-DateStringFromEpoch -epoch $e 
        }

        $s = $e + 0
        $remaining = $endEpochUtc - $e
   }

    return $slices
}

# note we return 1s 10 digit epoc times (not ms epcotimes)
function sumotime([string]$time) {
    
    if ($time -match 'm') {
        $multiplier = 60 
    }
    elseif ($time -match 's') {
        $multiplier = 1
    }
    elseif ($time -match 'h') {
        $multiplier = 60 * 60 
    }
    elseif ($time -match 'd') {
        $multiplier = 60 * 60 * 24
    }
    else { Write-Error "invalid sumo timespec must be m s h d (minutes, seconds, hours or days" }
    $t = $time -replace 'h|m|d|s|-', ''

    [bigint]$offset = ($t -as [int] ) * $multiplier 
    $now = [bigint][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s)) 
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
    return $from, $to
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
        $from, $to = sumolast($last)
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
        "query"           = $query
        "from"            = "$from"
        "to"              = "$to"
        "timeZone"        = $timeZone
        "byReceiptTime"   = $byReceiptTime
        "autoParsingMode" = $autoParsingMode
    }

    if ($dryrun ) {
        return $body
    }
    else {
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
        [parameter(Mandatory = $false)][string]  [ValidateSet("records", "messages")] $return = "records",
        [parameter(Mandatory = $false)][int] $limit = 1000

    )

    if ($job.id -and ($job.PSobject.Properties.name -match "messageCount") -and ($job.PSobject.Properties.name -match "recordCount") ) {

    }
    else { 
        Write-Error "passed -job object is missing required properties"
        return @()
    }

    $offset = 0

    if ($return -eq "records") {
        $totalresults = $job.recordCount
    }
    elseif ($return -eq "messages") {
        $totalresults = $job.messageCount
    }
    $remaining = $totalresults
    $resultSet = '{  "fields":[],  "records":[] , "messages": [] }' | ConvertFrom-Json

    While ($totalresults -gt 0 -and $remaining -gt 0) {
        $params = @{
            "offset" = $offset
            "limit"  = $limit
        }
        # get the page
        $page = (invoke-sumo -path "search/jobs/$($job.id)/$return" -method 'GET' -session $sumo_session   -v 'v1' -params $params)

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
        [parameter(Mandatory = $false)][string]  [ValidateSet("status", "records", "messages")] $return = "status"

    )

    if ($jobid) {
        Write-Verbose 'run by job id'

    }
    elseif ($job) {
        Write-Verbose 'run by job object'
        if ($job.id) {
            $jobid = $job.id
        }
        else { 
            Write-Error 'job object has no id property';
            return $job
        }
    }
    elseif ($query ) {
        Write-Verbose 'run by query'
        Write-Verbose "query: `n$($query | convertto-json -depth 10) `n"
        $job = New-SearchJob -body $query -sumo_session $sumo_session
        $jobid = $job.id
    }
    else {
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
        }
        else {
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
    }
    elseif ($return -eq "records") {
        $job_state | Add-Member -NotePropertyName records -NotePropertyValue (Export-SearchJobEvents -job $job_state -return 'records')
    }

    return  $job_state
}
