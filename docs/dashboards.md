# dashboards
This API is a bit odd in two ways:
1. it uses the ids you see in the sumo ui for a dashboard NOT the library dashboad ids.
2. there is no 'get all the dashboards' api call so you must use this with the library. There is a get-dashboards call but this is only for the user personal folder and has a limit of 100.

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

# Get Your Own Dashboards (Up to 100)
```
get-dashboards
```

# Getting dashboard content
use the get. 
```
Get-DashboardById -id ABCDEFdjZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8
```

# create and modify
Use the new-dasboard and Set-DashboardById passing the body in format from get-dashbaord.

Remember to set the folderId property to the new parent folder.

example new from existing.
```
$dash = Get-DashboardById -id rAFruP2IBelGE7cNNhUbyVEyOl8VXgflvI7H1kSQ1gLZwW6Xer3bmRghGthI -sumo_session $syd
$dash.folderId = (get-PersonalFolder -sumo_session $be).id  
$dash.PSObject.Properties.Remove('id') 
New-Dashboard -body $dash -sumo_session $be  
```

example update where exists in both.
```
$dash = Get-DashboardById -id QN90YWcYg1yM8aC9A2dH2LM45oNWCItSh1LiEeD7ba9ekPMCbAgcqB1JjdTj -sumo_session $be  
$dash.folderId = (get-PersonalFolder -sumo_session $syd).id 
$dash.PSObject.Properties.Remove('id') 
Set-DashboardById -id rAFruP2IBelGE7cNNhUbyVEyOl8VXgflvI7H1kSQ1gLZwW6Xer3bmRghGthI -body $dash -sumo_session $syd  
```

# Replacing query text with a regular expression
Often there is a use case to export a dashboard, make a replacement in all panels using a text patten then import the updated version (either in place or as a new dashboard).
This function replaces text matching a regular expression in each panel of a dashboard with a string and returns a new object.
The replace function is used so matching groups are also possible such as effectively ```-replace '.*(\w+)\.','$1'```

```
$d2 = Edit-DashboardPanelQueries -dashboard $dash -pattern 'foo' -replacewith 'bar' 
```
This new dashboard we could post using the new dashboard framework or import as a content item in the content api.

# using copy-proppy function to change dashboard content
We can use the copy-proppy function to hack round dashboard properties such as panel query strings, or to copy properties from one object to another.

from function help:
```
Returns a clone of the $to object.

with -props and -from 
will copy properties from to cloned object

with -replace_props, -replace_pattern, -with 
Text substitution of properties specified in either regex mode (default) or with -replace_mode 'text' change a text only mode.
If the property substitution is for a string property text replace is vs the string value.
Otherwise the replace is vs a 'json-ified' string of the object, which is then converted-back from json.
```

For example from tests:
```
# return clone object with copied title poperty, which we then replace
(copy-proppy -from $d1 -to $d2 -props @('title') -replace_props @('title') -replace_pattern 'B|B' -with 'XX' -replace_mode 'text' ).title | Should -match 'A XX C'
```

