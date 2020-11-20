# lookup tables.
https://api.au.sumologic.com/docs/#tag/lookupManagement

you can't see the actual rows via the API. to do this use the sumo search job api or UI and cat command:
```
cat path://"/Library/Users/user@acme.com/test1"
```

# creating a lookup
First create the schema either via the library UI in sumo or via the api with: New-LookupTable

The New-LookupTable function takes arguments to construct a table schema simplified.

## dryrun
```
New-LookupTable -name 'test' -parentFolderId (get-PersonalFolder).id -description 'a test lookup' -primaryKeys @('id') -columns @('id','value') -Verbose -dryrun $true
```

if we use ```-dryrun $true``` it will ouput a json schema for a lookup table. for example:
```
{
  "description": "a test lookup",
  "fields": [
    {
      "fieldType": "string",
      "fieldName": "id"
    },
    {
      "fieldType": "string",
      "fieldName": "value"
    }
  ],
  "primaryKeys": [
    "id"
  ],
  "ttl": 100,
  "sizeLimitAction": "DeleteOldData",
  "name": "test",
  "parentFolderId": "0000000000EDB78E"
}

```

## live create
as above but leave out -dryrun or set to $true

## finding lookup ids for existing tables
there is no way to get a list of lookup tables in this api. Instead you must use the content api to get the ids of a lookup using path.

For example:
```
(get-PersonalFolder -sumo_session $training).children | where {$_.itemType -eq 'Lookups'}
```
You can use the id property of the lookup objects for further API calls.

Or you can do this by path:
```
$lookupid = (get-ContentByPath -path '/Library/Users/janedoe@acme.com/test1' -sumo_session $training).id
```

## jobs
Many calls create a job which you need to poll for completion via Get-LookupTableJobsStatusById
The inital call in this case returns a jobid

# Row level actions
## removing a row by id

construct a column object with each primary key
```
$keys=@(@{'columnName' = 'id';'columnValue'='b'})
$body = @{"primaryKey" = $keys}
$body | convertto-json 

{
  "primaryKey": [
    {
      "columnValue": "b",
      "columnName": "id"
    }
  ]
} 
```

```
Remove-LookupTableRowById -id 0000000001111111 -body @{"primaryKey" = $keys} -sumo_session $training        
```

## adding /update a row 

first construct a row object similar to this example:
```
{
  "row": [
    {
      "columnValue": "g",
      "columnName": "id"
    },
    {
      "columnValue": "grapefruit",
      "columnName": "value"
    }
  ]
}
```


```
$row = @(@{'columnName' = 'id';'columnValue'='g'},@{'columnName' = 'value';'columnValue'='grapefruit'})
$body = @{"row" = $row} 
```

Then we an pass the object to update the row:
```
New-LookupTableRowById -id 0000000001111111 -body $body -sumo_session $training
```