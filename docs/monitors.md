# monitors

# Get-MonitorsRoot
gets the root of the monitors contentType : Folder tree including children list.

# Getting monitor folders or objects.

You can do this by id:
```
Get-MonitorsObjectById -id 0000000000002DEF
```

or by path:
```
Get-MonitorsObjectByPath -path '/Monitor/LB Demo Alerts'
```

to find the path use:
```
Get-MonitorsObjectPathById -id 0000000000002DEF
```
Get-MonitorsObjectPathById returns an object with pathItems collection and path string properties.

## search

you can search by a keyword or filters + keyword. string search is case insensitive

```
Get-MonitorsSearch -query 'Hosts'
(Get-MonitorsSearch -query 'createdBy:00000000009A7442 Hosts'
```

This returns a list of item/path formatted thus: 

```
item : @{id=0000000000002DF0; name=High HTTP 500; description=The count of 500 errors on the ALB is too high; version=0; createdAt=11/22/2020 11:45:49 PM; createdBy=00000000009A7442;                  modifiedAt=11/22/2020 11:45:49 PM; modifiedBy=00000000009A7442; parentId=0000000000002DEF; contentType=Monitor; type=MonitorsLibraryMonitorResponse; isSystem=False; isMutable=True;             monitorType=Metrics; queries=System.Object[]; triggers=System.Object[]; notifications=System.Object[]; isDisabled=False; status=System.Object[]; groupNotifications=True; warnings=}      
path : /Monitor/LB Demo Alerts/High HTTP 500

item : @{id=0000000000002DEF; name=LB Demo Alerts; description=demo alerts for load balancer; version=0; createdAt=11/22/2020 11:41:19 PM; createdBy=00000000009A7442; modifiedAt=11/22/2020 
       11:41:19 PM; modifiedBy=00000000009A7442; parentId=00000000000007A0; contentType=Folder; type=MonitorsLibraryFolderResponse; isSystem=False; isMutable=True; children=System.Object[]}
path : /Monitor/LB Demo Alerts

```

# getting bulk
returns a list of items with the item id as the key name.

Eample search showing results can include nested folder objects or monitor type objects.

```
Get-MonitorsBulkByIds -ids "0000000000002DEF,0000000000002DF0"
```

returned list object in JSON
```
{
	"0000000000002DEF": {
		"id": "0000000000002DEF",
		"name": "LB Demo Alerts",
		"description": "demo alerts for load balancer",
		"version": 0,
		"createdAt": "2020-11-22T23:41:19.878Z",
		"createdBy": "00000000009A7442",
		"modifiedAt": "2020-11-22T23:41:19.878Z",
		"modifiedBy": "00000000009A7442",
		"parentId": "00000000000007A0",
		"contentType": "Folder",
		"type": "MonitorsLibraryFolderResponse",
		"isSystem": false,
		"isMutable": true,
		"children": [{
				"id": "0000000000002DF0",
				"name": "High HTTP 500",
				"description": "The count of 500 errors on the ALB is too high",
				"version": 0,
				"createdAt": "2020-11-22T23:45:49.347Z",
				"createdBy": "00000000009A7442",
				"modifiedAt": "2020-11-22T23:45:49.347Z",
				"modifiedBy": "00000000009A7442",
				"parentId": "0000000000002DEF",
				"contentType": "Monitor",
				"type": "MonitorsLibraryBaseResponse",
				"isSystem": false,
				"isMutable": true
			},
			{
				"id": "0000000000002DF2",
				"name": "Unhealthy Hosts",
				"description": "There are unhealthy hosts reporting to the loadbalancer.",
				"version": 2,
				"createdAt": "2020-11-22T23:46:11.522Z",
				"createdBy": "00000000009A7442",
				"modifiedAt": "2020-11-23T01:36:47.846Z",
				"modifiedBy": "00000000009A7442",
				"parentId": "0000000000002DEF",
				"contentType": "Monitor",
				"type": "MonitorsLibraryBaseResponse",
				"isSystem": false,
				"isMutable": true
			}
		]
	},
	"0000000000002DF0": {
		"id": "0000000000002DF0",
		"name": "High HTTP 500",
		"description": "The count of 500 errors on the ALB is too high",
		"version": 0,
		"createdAt": "2020-11-22T23:45:49.347Z",
		"createdBy": "00000000009A7442",
		"modifiedAt": "2020-11-22T23:45:49.347Z",
		"modifiedBy": "00000000009A7442",
		"parentId": "0000000000002DEF",
		"contentType": "Monitor",
		"type": "MonitorsLibraryMonitorResponse",
		"isSystem": false,
		"isMutable": true,
		"monitorType": "Metrics",
		"queries": [{
			"rowId": "A",
			"query": "metric=HTTPCode_ELB_500_Count namespace=aws/applicationelb statistic=sum | avg by entity"
		}],
		"triggers": [{
				"detectionMethod": "StaticCondition",
				"timeRange": "-15m",
				"triggerType": "Critical",
				"threshold": 19.0,
				"thresholdType": "GreaterThanOrEqual",
				"occurrenceType": "Always",
				"triggerSource": "AnyTimeSeries"
			},
			{
				"detectionMethod": "StaticCondition",
				"timeRange": "-15m",
				"triggerType": "ResolvedCritical",
				"threshold": 19.0,
				"thresholdType": "LessThan",
				"occurrenceType": "Always",
				"triggerSource": "AnyTimeSeries"
			}
		],
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