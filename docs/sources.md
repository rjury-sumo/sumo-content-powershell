# sources
There is already a good public library for updates etc the sumologic-powershell-sdk!

we have a few methods

-id is the collector id
-sourceid is the source id

## get-sources
gets all sources for a given collector id
```
$sources = get-sources -id $collector.id | where {$_.name -match $sourcesMatch}
```

## get-sourcebyid
returns a single source by id and collector id
```
get-sourcebyid -sourceid 179089716 -id 110238720
```
