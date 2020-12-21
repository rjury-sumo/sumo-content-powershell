# search jobs
There already is a search job api command in the sumologic-powershell-sdk. This is an alternative implementiation.

there are many options of how to do this recommended way is:
- run new-searchjobquery to create a query object, or a job
- run get-searchjobresult passing the query or job object.

# use cases
## create query body object for the api.
```
New-SearchJobQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true
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
New-SearchJobQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-15m'
New-SearchJobQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-7d -1d'
```

## running a search job only
Executing the above without -dryrun executes the query and returns a job object for example:

```
New-SearchJobQuery -query 'error| count by _sourcecategory | limit 7' | convertto-json -Depth 10 -Compress

{"id":"2B678BB457D0E8A1","link":{"rel":"self","href":"https://api.us2.sumologic.com/api/v1/search/jobs/2B678BB457D0E8A1"}} 
```

## run a search job with a custom job body
You can execute a job directly with a custom body, this returns a job object with an id and link.
```
New-SearchJob  -body $body
```

## running a job and polling for completion to get status, records or messages
One might want to:
- run a search job only (say to save to lookup)
- run a search job and return messages at completion
- run a search job and return records (aggregate) results at completion

### use a query object
First create a query body object for example:
```
$q = New-SearchJobQuery -query 'error| count by _sourcecategory | limit 7' -dryrun $true -last '-15m'

get-SearchJobResult -query $q -return status  
```

### use a job object
First create a job for example:
```
$job = New-SearchJobQuery -query 'error| count by _sourcecategory | limit 7' -last '-15m'
get-SearchJobResult -job $job -return status  
```

### use a job id
For any valid job id
```  
get-SearchJobResult -jobid $id -return status  
```

## Retrieving results
You can retrieve just status or the raw messages and records (aggregates).

```
get-SearchJobResult -job $job -return status  
```

or get the aggregate results:
```
get-SearchJobResult -job $job -return records  
```

or get the raw messages
```
get-SearchJobResult -job $job  -return messages  
```

### messages and records properties
- In the case of messages a messages property is added containing the result pages with properties: fields, messages which is a list of objects with a map property.

- In the case of records a records property is added containing the result pages with properties: fields, records which is a list of objects with a map property.

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
this polls the api a single time and returns a job status object by jobid