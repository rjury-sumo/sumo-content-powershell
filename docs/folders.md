
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
