# sumo-content-powershell
powershell commands for interacting with content and folder apis

# Examples of usage

## make a new session
Make a new session using defuatl env vars for endpoint and credentials.
Get a content item by id or path.

```
new-ContentSession
```

## Get A folder
Get an item by id. Note if you want to recurse only the get by id includes children in the returned object!
```
get-Folder -id $export_id  
```

You can also get the path and get items by path. Path items don't have children returned.
```
$export_item_path = get-ContentPath -id $export_id
$item_by_path = get-ContentByPath -path $export_item_path
```

## Export content from a session
Create a new session and export the 'test' item in the personal folder
```
new-ContentSession -endpoint 'https://api.au.sumologic.com' 
$FolderNameToExport = "test"
$parent_folder = get-PersonalFolder 
$export_id = ($parent_folder.children | where {$_.ItemType -eq "Folder" -and $_.name -eq $FolderNameToExport}).id
$export_item =  get-ExportContent -id $export_id
$export_item |  ConvertTo-Json -Depth 100 | Out-File -FilePath ./temp.json -Encoding ascii -Force -ErrorAction Stop
```

## import content from a file
Import content into the personal folder using the default session
```
$parent_folder = get-PersonalFolder 
start-ContentImportJob -folderId $parent_folder.id -contentJSON (gc -Path ./temp.json -Raw) 
```

to overwrite existing content use overwrite:
```
start-ContentImportJob -folderId $parent_folder.id -contentJSON (gc -Path ./temp.json -Raw) -overwrite 'true'
```
