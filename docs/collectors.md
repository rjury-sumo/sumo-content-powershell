# collectors

note: there is already a sumo-powershell-sdk with comprehensive methods for collectors and sources so this is a low priority for this project.

## get collectors
Get collectors. Use -limit -offset params are required.
```
get-collectors
```

## get-offlineCollectors
gets a list of installed collectors that are offline.


## getting specific collectors

get by id
```
get-collectorById -id 123456789
``` 

get by name
```
get-collectorByName -name test
```