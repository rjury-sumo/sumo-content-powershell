# dashboards
This API is a bit odd in two ways:
1. it uses the ids you see in the sumo ui for a dashboard NOT the library dashboad ids.
2. there is no 'get all the dashboards' api call so you must use this with the library.

# ids
The dashboard ids required are the ones you see in the URI in sumo such as: ABCDEwxyze6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8.
If you create a dashboard the api will return the id of the created object. 
For existing ones you can only easily get their id via the url in the sumo UI.

## converting a dashboard id to content id
we can use this function

```
Get-DashboardContentIdById -id ABCDEFdjZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8
```
which returns the decimal converted to library hex id.

## mapping library content id to dashboards id.
the process to map a library id to dashboard id is as follows:
have not found a way to do this as as sumo customer...

```
(Get-ContentFolderById -id 0000000000F3D7E2).children[0]
````

might return something like:
```
createdAt   : 11/19/2020 2:13:32 AM                                                                                                                                         
createdBy   : 00000000009A779D                                                                                                                                              modifiedAt  : 11/19/2020 2:14:11 AM                                                                                                                                         
modifiedBy  : 0000000000123456
id          : 0000000000ABCDEF
name        : API Example
itemType    : Dashboard
parentId    : 0000000000FEDCBA
permissions : {GrantEdit, View, Edit, GrantView…}
```
note the id in hex - but we cannot from here map to a dashboards id other than by opening it in the ui and noting the url.

# Getting dashboard content
use the get. 
```
Get-DashboardById -id ABCDEFdjZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8
```

# create and modify
Use the new-dasboard and Set-DashboardById passing the body in format from get-dashbaord.