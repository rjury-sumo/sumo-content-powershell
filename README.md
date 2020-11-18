# sumo-content-powershell
powershell commands for interacting with content and folder apis

## src
theses are the source files to dot source the functions.
for now it's not a psm just dot source.

## endpoints
this folder contains some files with sumo api endpoints and automation to bulk generate api code.

# setup
right now this is not a true module. 

To use is 'dot source' it in a powershell session to create the functions and sumo data type:
```
foreach ($f in dir ./src/*.ps1) { . $f.fullname }
```

# Examples of usage

## make a new session
Make a new session using defuatl env vars for endpoint and credentials.
The session is saved as a global variable which subsequent commands will default to sumo_session=$sumo_session
Get a content item by id or path.

```
new-ContentSession -endpoint 'au'
```

or multiple sessions:

```
$test = new-ContentSession -endpoint 'au'
$live = new-ContentSession -endpoint 'us2' -accessid $env:accessidlive -accesskey $env:accesskeylive
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

# Using the docker image

## custom entry point
By default a pwsh prompt is the entry point. .
Then modify the entrypoint e.g
```
ENTRYPOINT ["pwsh","-File","/home/demo.ps1"]
```

## Build the docker container
to build run
```
docker build -t sumologic-content-powershell:latest .
```

## Starting the container

### windows powershell
```
docker run --env SUMO_DEPLOYMENT=us2 --env SUMO_ACCESS_ID=$Env:SUMO_ACCESS_ID --env SUMO_ACCESS_KEY=$Env:SUMO_
ACCESS_KEY -it sumologic-content-powershell:latest
```

### bash
```
docker run --env SUMO_DEPLOYMENT=au --env SUMO_ACCESS_ID=$SUMO_ACCESS_ID --env SUMO_ACCESS_KEY=$SUMO_ACCESS_KEY -it sumologic-content-powershell:latest
```

# Tests
both code solutions have a pester test file with some rather incomplete test coverage!

# TODO
- make it a real module not dot source
- migrate more api commands from the endpoints/src after validating/testing
- write more unit test.
