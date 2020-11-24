# monitors

# Get-MonitorsRoot
gets the root of the monitors contentType : Folder tree including children list.

# Getting monitor folders or objects.

## by id
You can do this by id two ways that produce similar but not same outputs

return a MonitorsLibraryMonitorResponse object:
```
Get-MonitorsObjectById -id 0000000000002DEF
```

return a MonitorsLibraryMonitorExport object:
```
Get-MonitorExportById -id 0000000000002DF2
```

## by path
or by path:
```
Get-MonitorsObjectByPath -path '/Monitor/LB Demo Alerts'
```

### finding path by id
to find the path use:
```
Get-MonitorsObjectPathById -id 0000000000002DEF
```
Get-MonitorsObjectPathById returns an object with pathItems collection (a heirarchy) and path string properties.

## by search

you can search by a keyword or filters + keyword. string search is case insensitive

```
Get-MonitorsSearch -query 'Hosts'
Get-MonitorsSearch -query 'createdBy:00000000009A7442 Hosts'
```
This returns a list of objects with an item and path property

## by getting bulk by id list
returns a list of items with the item id as the key name.
Eample search showing results can include nested folder objects or monitor type objects.

```
Get-MonitorsBulkByIds -ids "0000000000002DEF,0000000000002DF0"
```

returned list object which if we convert to JSON appear thusly...
```
{
	"0000000000002DEF": {
		"id": "0000000000002DEF",
		"name": "LB Demo Alerts",
		"description": "demo alerts for load balancer",
		...}
	},
	"0000000000002DF0": {
		"id": "0000000000002DF0",
		"name": "High HTTP 500",
		"description": "The count of 500 errors on the ALB is too high",
		...
		"notifications": [],
		"isDisabled": false,
		"status": [
			"Normal"
		],
		"groupNotifications": true,
		"warnings": null
	}
}
```

# checking usage

get-MonitorsUsageInfo returns a list
```
logsMonitorUsageLimit     : 100
totalLogsMonitorCount     : 7
activeLogsMonitorCount    : 6
metricsMonitorUsageLimit  : 100
totalMetricsMonitorCount  : 4
activeMetricsMonitorCount : 2
```

# creating, moving, copying and deleting.
For move and copy we have a simplifed function where you supply the id and parentid for example:
```
Copy-MonitorById -id 0000000000002DF0 -parentid 0000000000002DEF -name 'api copy test' -description 'api copy test'
```

to remove use: 
```
Remove-MonitorById -id 0000000000002F0D  
```

to update or create at this point the methods are still basic where you must contruct and supply the body object for example:

```
 Set-MonitorById [[-sumo_session] <SumoAPISession>] [-id] <Object> [-body] <Object> [<CommonParameters>]
```