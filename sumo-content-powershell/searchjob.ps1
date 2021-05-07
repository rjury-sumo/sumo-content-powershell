# an alternative to the sumologic powerhshell sdk start-searchjob

<#
.SYNOPSIS
returns an epch time in ms or not from a date string provided.

.PARAMETER epochDate
Optinoal date, if not provided returns now

.PARAMETER format
can be auto in which case powershell tries default casting or a foramt string for ParseExact.

.OUTPUTS
long object as a ms or non ms ecoch time.

#>

Function get-epochDate () { 
    Param(
        [parameter(Mandatory = $false)][string] $epochDate,
        [parameter(Mandatory = $false)][string] $format = 'auto', # or say 'MM/dd/yyyy HH:mm:ss',
        [parameter(Mandatory = $false)][bool] $ms = $true

    )
    if ($epochDate) {
        try { 
            if ($format -eq 'auto') {
                $date = [datetime]$epochDate
            }
            else {
                $date = [Datetime]::ParseExact($epochDate, $format, $null)
            }
            $dateUTC = $date.ToUniversalTime()
            [int]$epoch = Get-Date $dateUTC -UFormat %s
        }
        catch {
            Write-Error "An error occurred parsing $epochDate using format string: $format"
            Write-Error $_.ScriptStackTrace
        }
    }
    else {
        $epoch = [int][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s))
    }
    if ($ms) { [long]$epoch = $epoch * 1000 }
    return $epoch
}

# return a date string represenation of a epochtime
Function get-DateStringFromEpoch ($epoch) { 
    if ($epoch.toString() -match '[0-9]{13,14}' ) {
        $epoch = [long]($epoch / 1000)
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

.PARAMETER intervalms
an interval for timeslices expressessed as ms. default is 1 hour

.OUTPUTS
long object as a ms or non ms ecoch time.
example timeslice object:
Name                           Value
----                           -----
interval_ms                    3600000
startString                    04/05/2021 00:00:00
endString                      04/05/2021 01:00:00
start                          1617537600000
end                            1617541200000

#>

Function get-timeslices () { 
    Param(
        [parameter(Mandatory = $true)] $start,
        [parameter(Mandatory = $true)] $end,
        [parameter(Mandatory = $false)] [long]$intervalms = (1000 * 60 * 60)
    )

    $startEpocUtc = get-epochDate -epochDate $start
    $endEpochUtc = get-epochDate -epochDate $end

    $slices = @()
    $remaining = $endEpochUtc - $startEpocUtc
    $s = $startEpocUtc
    Write-Verbose "$start $startEpocUtc $end $endEpochUtc $s $remaining"

    while ($remaining -gt 0) {
        $e = $s + $intervalms

        if ($e -gt $endEpochUtc) { 
            $e = $endEpochUtc;
            $intervalms = $endEpochUtc - $s
        }
        else {
            $e = $s + $intervalms
        }

        $slices = $slices + @{ 
            'start'       = [long]$s; 
            'end'         = [long]$e; 
            'intervalms'  = [long]$intervalms; 
            "startString" = get-DateStringFromEpoch -epoch $s; 
            "endString"   = get-DateStringFromEpoch -epoch $e 
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

    [long]$offset = ($t -as [int] ) * $multiplier 
    $now = [long][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s)) 
    return [long]($now - $offset)
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
        return [long]($epoc / 1000)
    }
    elseif ($epoc.toString() -match '[0-9]{10}' ) {
        return [long]($epoc )
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

.PARAMETER byReceiptTime
string boolean Define as true to run the search using receipt time. By default, searches do not run by receipt time.

.PARAMETER autoParsingMode
This enables dynamic parsing, when specified as intelligent, Sumo automatically runs field extraction on your JSON log messages when you run a search. By default, searches run in performance mode.

.PARAMETER dryrun
if set to true function returns the query object that wouuld be submitted as -body
if set to false starts the search job and add's an id property to the return object.

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
        [parameter()][long]$from,
        [parameter()][long]$to,
        [parameter()][string]$query,   
        [parameter()][string]$file, 
        [parameter()][string]$last,
        [parameter()][string]$timeZone = 'UTC',
        [parameter()][string]$byReceiptTime = 'False',
        [parameter()][string]$autoParsingMode = 'performance',
        [parameter(mandatory = $false)][bool]$dryrun = $true,
        [Parameter(Mandatory = $false)][array]$substitutions

    )

    $utcNow = [long][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s)) * 1000

    # we must have a valid query
    if ($query) {
    }
    elseif ($file) {
        [string]$query = Get-Content -Path $file -Raw
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
        $to = epocvalidation($to)
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

.EXAMPLE
$q = New-SearchQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-15m'
get-SearchJobResult -query $q -return status  

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
        [parameter(Mandatory = $false)][int] $max_tries = 120,
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
    
    $tries = 1
    $last = "none"

    While ($jobid -and ($max_tries -gt $tries)) {
        $tries = $tries + 1     
        Write-Verbose "polling job $jobid. try: $tries of $max_tries"
        
        $job_state = get-SearchJobStatus -jobId $jobid -sumo_session $sumo_session
        if ($last -ne $job_state.state) {
            Write-Verbose "change status: from: $last to $($job_state.state) at $($tries * $poll_seconds) seconds."
            $last = "$($job_state.state)"
        }
        else {
            Write-Verbose  ($job_state.state)
        }

        if ($job_state.state -eq 'DONE GATHERING RESULTS') {
            write-host "$($job_state.state) at $($tries * $poll_seconds) seconds."
            break
        }
        else {
            Start-Sleep -Seconds $poll_secs
        }

        # add the jobid 
        
    }   
    Write-Verbose "job poll completed: status: $($job_state.state) jobId: $jobid"
    if ($job_state.state -ne 'DONE GATHERING RESULTS') {
        Write-Error "Job failed or timed out for job: $jobid `n $($job_state | out-string)" -ErrorAction Stop; 
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



<#
.SYNOPSIS
Creates a query batch for repeating queries over a series of timeslices.

.DESCRIPTION
Run a query lots of times in series, useful for bulk data operationas such as export or building a view.
Creates an output job folder for example: ./output/jobs/bf512d66-6261-4cfd-bdbc-9d0c94a86e50  
This folder contains as queries folder of each query object to execute, and if dryrun=false each query is executed and output stored in the completed folder.

.PARAMETER sumo_session
Specify a session, defaults to $sumo_session

.PARAMETER query
the query string to run in the batch job.

.PARAMETER file
alternative to -query you can specify a file path of a query text file.

.PARAMETER outputPath
writes each job output to a path specified. Defaults to ./output

.PARAMETER startTimeString
start time  for the job

.PARAMETER endTimeString
end time  for the job

.PARAMETER intervalMs
ms intervals for batching start and end times.

.PARAMETER byReceiptTime
string boolean Define as true to run the search using receipt time. By default, searches do not run by receipt time.

.PARAMETER autoParsingMode
This enables dynamic parsing, when specified as intelligent, Sumo automatically runs field extraction on your JSON log messages when you run a search. By default, searches run in performance mode.

.PARAMETER poll_secs
default 1, the poll interval to check for job completion.

.PARAMETER max_tries
default 120, the maximumum number of poll cycles to wait for completion

.PARAMETER return
"status","records","messages"
status returns on the job result object
records adds a records property contining the records results pages
messages adds a messages property containing the messages results pages

.EXAMPLE
Create a batch job of queries 
New-SearchBatchJob -query 'error | limit 1'  -dryrun $false -return records

.EXAMPLE
batch job with more options
New-SearchBatchJob -query 'error | limit 5' -dryrun $false -return records -startTimeString ((Get-Date).AddMinutes(-60)) -endTimeString (Get-Date) -sumo_session $sanbox

.EXAMPLE
Run a query with query string in a text file.
New-SearchBatchJob -file './library/example.sumo' -dryrun $true  -return records -startTimeString ((Get-Date).AddMinutes(-180)) -endTimeString 'Wednesday, May 5, 2021 5:15:22 PM'

.OUTPUTS
returns the path of the batch job output and other properites as an object
for example:
Name                           Value                                                                                                                         ----                           -----                                                                                                                         
errors                         2
recordCount                    0
outputPath                     ./output/jobs/d3f059e6-c77f-432d-8631-29915c66d0a0
messageCount                   0
queries                        2
query                          some query
executed                       2
pendingWarnings                {}
pendingErrors                  {Field org_id not found, please check the spelling and try again. (520)}

#>
function New-SearchBatchJob {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $false)] [string]$query, 
        [parameter(Mandatory = $false)] [string]$file, 
        [parameter(Mandatory = $false)] [string]$outputPath = './output', 
        [parameter(Mandatory = $false)] [string]$startTimeString = (Get-Date).AddMinutes(-60),
        [parameter(Mandatory = $false)] [string]$endTimeString = (Get-Date), 
        [parameter(Mandatory = $false)] [int]$intervalMs = (1000 * 60 * 60), 
        [parameter()] [string][ValidateSet("true", "false")] $byReceiptTime = 'False',
        [parameter()] [string][ValidateSet("performance", "intelligent")]$autoParsingMode = 'performance',
        [parameter(Mandatory = $false)][int] $poll_secs = 1,
        [parameter(Mandatory = $false)][int] $max_tries = 120,
        [parameter(Mandatory = $false)][string][ValidateSet("status", "records", "messages")] $return = "status",
        [parameter(mandatory = $false)][bool]$dryrun = $true
    )

    $batchJob = new-guid
    $yyyymmdd = (get-date).tostring("yyyyMMdd_hhmmss")
    $batchJob = "$($yyyymmdd)_$($batchJob)"

    # we must have a valid query
    if ($query) {
    }
    elseif ($file) {
        [string]$query = Get-Content -Path $file -Raw
    }
    else {
        Write-Error "New-SearchJob requires either -query or -file"
        return $null
    }

    write-host "Starting Batch Job: $batchjob at $(get-date)"
    Write-Verbose "start: $startTimeString end: $endTimeString intervalms: $intervalMs byreceittime: $byReceiptTime autoparsemode: $autoParsingMode poll_secs: $poll_secs retries: $max_tries"

    try {
        $timeslices = get-timeslices -start $startTimeString -end $endTimeString -intervalms $intervalMs
    }
    catch {
        Write-Error "An error occurred generating timeslices for $startTimeString to endTimeString with interval: intervalMs"
        Write-Error $_.ScriptStackTrace
    }

    New-Item -path "$outputPath" -Type Directory -ErrorAction SilentlyContinue -force | out-null
    New-Item -path "$outputPath/jobs/$batchjob/queries" -Type Directory -ErrorAction SilentlyContinue -force | out-null
    New-Item -path "$outputPath/jobs/$batchjob/completed" -Type Directory -ErrorAction SilentlyContinue -force | out-null

    $i = 0
    $executed = 0
    $errors = 0
    $messageCount=0
    $recordCount=0
    $pendingWarnings=@{}
    $pendingErrors=@{}


    foreach ($slice in $timeslices) {
        $i = $i + 1
        Write-Host "$i  from: $($slice['startString'])    to: $($slice['endString'])    file: $outputPath/jobs/$batchjob/queries/query_$($slice['start'])_$($slice['end']).json"
        try {
            $sliceQuery = new-searchQuery -query $query -from $slice['start'] -to $slice['end'] $query -byReceiptTime $byReceiptTime -autoParsingMode $autoParsingMode -sumo_session $sumo_session -dryrun $true #-verbose
            $sliceQuery | convertto-json -depth 10 | out-file -filepath "$outputPath/jobs/$batchjob/queries/query_$($slice['start'])_$($slice['end']).json"

            if ($dryrun -eq $false ) {
                write-host "Executing job: $i from $($slice['startString']) end $($slice['endString'])"
                $result = get-SearchJobResult -query $sliceQuery -sumo_session $sumo_session -poll_secs $poll_secs -max_tries $max_tries -return $return
                $jobpath = "$outputPath/jobs/$batchjob/completed/query_$($slice['start'])_$($slice['end']).json"
                write-verbose "writing output to: $jobpath"
                $result | convertto-json -depth 10| out-file -filepath $jobpath
                $executed = $executed + 1 
                if ($result.messagecount) { $messageCount=$result.messageCount+ 0}
                if ($result.recordcount) { $recordcount=$result.recordcount}
                if ($result.pendingWarnings) { 
                    foreach ($warning in $result.pendingWarnings) {
                        if($pendingWarnings["$warning"]) {
                            $pendingWarnings["$warning"]=$pendingWarnings["$warning"] + 1
                        } else {
                            $pendingWarnings["$warning"]=1
                        }
                    }
                }

                if ($result.pendingErrors) { 
                    foreach ($error in $result.pendingErrors) {
                        if($pendingErrors["$error"]) {
                            $pendingErrors["$error"]=$pendingErrors["$error"] + 1
                        } else {
                            $pendingErrors["$error"]=1
                        }
                        $errors = $errors + 1
                    }
                }
            }
        }
        catch {
            Write-Error "An error occurred executing query slice from $($slice['startString']) end $($slice['endString'])"
            Write-Error $_.ScriptStackTrace
            $errors = $errors + 1
        }
    }

    $result  = @{
        "queries" = $i;
        "executed" =  $executed;
        "errors"  = $errors;
        "messageCount" = $messageCount;
        "recordCount" = $recordCount;
        "pendingWarnings" = $pendingWarnings;
        "pendingErrors" = $pendingErrors;
        "outputPath" = "$outputPath/jobs/$batchjob";
        "query" = $query;
    }

    Write-Verbose ($result | convertto-json | Out-String)
    return $result 
}

