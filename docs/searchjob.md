# search jobs
There already is a search job api command in the sumologic-powershell-sdk. This is an alternative implementiation.

there are many options of how to do this recommended way is:
- run new-searchjobquery to create a query object, or a job
- run get-searchjobresult passing the query or job object

This module also has a batch query mode: New-SearchBatchJob for running a query vs multiple time slices as a batch job. This can be useful for exporting data or building custom views.

# How to create query object with New-SearchQuery.
With -dryrun $true (defaut) returns a query object for use with search job API.

```
New-SearchQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true
```

produces a body object for the API for example:
```
{
  "query": "error| count by _sourcecategory | limit 7",
  "autoParsingMode": "performance",
  "from": "1608522282000",
  "to": "1608522582000",
  "timeZone": "UTC",
  "byReceiptTime": "False"
}
```

## setting a time range
You can add arguments for -from and -to as epoc times, or use -last for example similar to the Sumo UI syntax:
```
New-SearchQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-15m'
New-SearchQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-7d -1d'
```

# How to Execute a Search Job And Return status/reocrds/messages
Typical workflow is to create a query object then execute that as a search job, poll for results then return a result object (status, records or messages).

get-SearchJobResult  has several modes:
- query: runs a query using a query object (from new-searchquery)
- job: polls and returns results of an existing created job 
- jobid: polls and returns results for a existing job by id

```
$q = New-SearchQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-15m'
get-SearchJobResult -query $q -return status  
```
The return mode can be:
- status: wait for completion and return just the status object
- records: add records array to the status object. This is for aggregate queries.
- messages: add messages object to the status object (slowest - raw results).

# How to run a batch job

this would constuct three query objects, one for each hour for the last three hours, then execute each query. 

Both the queries and the output status results are stored in the ./output/ folder

the command returns the path to the output objects for example: 
```
./output/jobs/706a9e33-a6c7-4c61-88c7-e8a388f6b11a
```

within this folder there will be a queries folder with 1 json file per query (in either mode).

In dryrun false mode the queries will execute and there is 1 file per job result in json format in the completed folder.

```
New-SearchBatchJob -query 'error | limit 5' -dryrun $false -return records -startTimeString ((Get-Date).AddMinutes(-180)) -endTimeString (Get-Date) -sumo_session $sanbox
```

# How to start a search job and return the Id only
Executing the New-SearchQuery -dryrun $false **executes the query and returns a job object** for example:

```
New-SearchQuery -query 'error| count by _sourcecategory | limit 7' | convertto-json -Depth 10 -Compress
```
returns a job object:
```
{"id":"21A344FC2BE4588B","link":{"rel":"self","href":"https://api.au.sumologic.com/api/v1/search/jobs/21A344FC2BE4588B"}}  
```

## run a search job with a custom job body
You can execute a job directly with a custom body, this returns a job object with an id and link.
```
New-SearchJob  -body $body
```

# Other Commands

### use a job object
First create a job for example:
```
$job = New-SearchQuery -query 'error| count by _sourcecategory | limit 7' -last '-15m'
get-SearchJobResult -job $job -return status  
```

### use a job id
For any valid job id
```  
get-SearchJobResult -jobid $id -return status  
```

## Retrieving results
You can retrieve just status or the raw messages and records (aggregates) for any of the three methods above.

## status only
```
get-SearchJobResult -job $job -return status  
```

## records
or get the aggregate results:
```
get-SearchJobResult -job $job -return records  
```
In the case of records a records property is added containing the result pages with properties: fields, records which is a list of objects with a map property.

## messages
or get the raw messages
```
get-SearchJobResult -job $job  -return messages  
```
In the case of messages a messages property is added containing the result pages with properties: fields, messages which is a list of objects with a map property.

## messages and records properties

## query substitutions
You can add a substitutions array to the new-searchquery command to parameterize queries. 

For example:
```
New-SearchQuery -query 'foo bar i have a red apple' -substitutions @(@{'replace'='foo';'with'='bar'},@{'replace'='red';'with'='blue'};) -dryrun $true 
```

would return 'barr bar i have a blue apple' as the query.

## helper functions
This module contains some helper functions that might be useful.

### sumolast
calculates a 'last' sumo range as epoch from,to

```
sumolast ('-15m')
1608522601
1608523501
```

### get-SearchJobStatus
This polls the api a single time and returns a job status object by jobid

