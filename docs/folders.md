# folders
note isAdminMode can change what you return for some of these calls.

common folder properties used:
children,createdBy,id,modifiedAt,name,permissions,createdAt,description,itemType,modifiedBy,parentId

Note if you want to recurse only the get by **id** includes children in the returned object!

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

## admin recommended and global folders
You must start an export job for these. If you get-adminrecommended/get-global you get back just the id of the export job.
This will return a list of children content objects that do NOT include a children property.

```
get-folderGlobalContent -type global
get-folderGlobalContent -type adminRecommended
``` 

## create a folder
use new-folder specifying the parent folder id.

```
new-folder -parentId (get-PersonalFolder -sumo_session $sumo).id -name 'api-create-test'
```