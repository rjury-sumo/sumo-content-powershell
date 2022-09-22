# folders

## Peculiar Things to Note About This API
Note: For certain APIs such as the Content api to access admin recommended you must use isAdminMode true however you don't need to use isAdminMode to use the dedicated endpoints for exporting the top level Global or Admin Recommended object.

get-folder -id xxx returns an object with a children property but the Content API equivalent by path does not if that path is a folder.

## Getting a child list for the global or admin recommended folders
There are a number of calls required so use get-folderGlobalContent  (see below)

## Get A folder
Get an item by id using either of these:
```
get-Folder -id $export_id  
Get-ContentFolderById -id ((get-personalfolder).children | where {$_.name -match '^api-create-test$'}).id
```

You can also get the path and get items by path. Path items don't have children returned.
```
$export_item_path = get-ContentPath -id $export_id
$item_by_path = get-ContentByPath -path $export_item_path
```

## personal folder
return the personal folder object.

```
get-PersonalFolder  
```

## get-folderGlobalContent: admin recommended and global folders
Accessing global folders is complex vs personal folder so to simplify you can simply call get-folderGlobalContent

```
get-folderGlobalContent -type global
get-folderGlobalContent -type adminRecommended
``` 

This will return a list of children content objects that do NOT include a children property so you must use get-folder on those to recurse.

## behind the scenes
this will start an export job using the global or admin recommended endpoint using say: ```https://api.au.sumologic.com/api/v2/content/folders/adminRecommended```

You must start an export job for these. If you get-adminrecommended/get-global you get back **just the id of the export job**.
You must then poll the job till completion and return an actual id and child object.
One the job is completed you can request the result for example: ```https://api.au.sumologic.com/api/v2/content/folders/adminRecommended/{jobId}/result ```



## create a folder
use new-folder specifying the parent folder id.

```
new-folder -parentId (get-PersonalFolder -sumo_session $sumo).id -name 'api-create-test'
```