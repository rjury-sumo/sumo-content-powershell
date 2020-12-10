# content 
note isAdminMode can change what you return for some of these calls.

You can access by path or id.
NOTE: getting a folder by path does NOT return the chidren property.
If you want to recurse folders use get by 'get-Folder -id $id' instead!

```
get-ContentPath -id $f.id 
get-contentbypath -path  '/Library/Users/johndoe@acme.com'
````

## content exports
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
The import imports the supplied body into the folder that you specify by ID.

Import content into the personal folder using the default session
```
$parent_folder = get-PersonalFolder 
start-ContentImportJob -folderId $parent_folder.id -contentJSON (gc -Path ./temp.json -Raw) 
```

this returns a hash with folderid and jobid keys.

To determine if the job was successful check with:
```
Get-ContentFoldersImportStatusById -folderId 0000000000F73745 -jobId A22A47F41D24C154
```

to overwrite existing content use overwrite:
```
start-ContentImportJob -folderId $parent_folder.id -contentJSON (gc -Path ./temp.json -Raw) -overwrite 'true'
```


## Migrate content from one instance to another
Here we create two sessions dev and live using different access keys.

subsequent commands we must pass the sumo_session variable to ensure it targets the correct session.
```
$dev = new-ContentSession -endpoint 'https://api.au.sumologic.com' -accessid $env:SAI_DEV -accesskey $env:SAK_DEV
$live = new-ContentSession -endpoint 'https://api.au.sumologic.com' -accessid $env:SAI_LIVE -accesskey $env:SAK_LIVE   

$from_folder=(get-PersonalFolder -sumo_session $dev).children | where {$_.name -match 'Use Case Examples'}
$to_folder=(get-PersonalFolder -sumo_session $live).children | where {$_.name -match 'LiveFolder'}
get-ExportContent -id $from_folder.id -sumo_session $dev |  ConvertTo-Json -Depth 100 | Out-File -FilePath ./data/export.json
start-ContentImportJob -folderId $to_folder.id -contentJSON (gc -Path ./data/export.json -Raw) -overwrite 'true' -sumo_session $live
```

# Exporting specific content from a folder

We can export all content from a folder in say the personal folder, locating it by it's name property.

```
$tf=(get-PersonalFolder).children | where {$_.name -eq 'tf'}

get-ExportContent -id $tf.id | convertto-json -depth 100 | out-file -FilePath ./dash-old/tf.solution.json
```

It's also posssible to locate specific content in a folder in the children list, then use that id to export specific content items.

getArrayIndex is a custom function to return an item from a list of hash/ custom objects using a name pattern vs a specific property.

```
# get folder by id so we get the children list.
$tf_folder = Get-ContentFolderById -id $tf.id

# search the children and locate the element by name property
$example = getArrayIndex $tf_folder.children '^Example Dashboard$'

# example includes basic properties like name and id but not content.
# run an export job for just the child item.
get-ExportContent -id ($tf_folder.children[$example]).id| convertto-json -depth 100 | out-file "./example_$(($tf_folder.children[$example]).id).json"

```