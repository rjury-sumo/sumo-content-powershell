# connect with default env vars
Make a new session using defuatl env vars for endpoint and credentials.

```
new-ContentSession -endpoint 'au'
```

# using defaul session
the most recent session is saved as a global variable in the shell and used by andy content functions as default -sumo_session.

# custom creds and endpoint
Store a $be session variable. Later we can use -sumo_session $be to use this session.
```
$be = new-ContentSession -endpoint us2 -accessid $env:SUMO_ACCESS_ID_BE -accesskey $env:SUMO_ACCESS_KEY_BE
```

# start two sessions
```
$dev = new-ContentSession -endpoint 'https://api.au.sumologic.com' -accessid $env:SAI_DEV -accesskey $env:SAK_DEV
$live = new-ContentSession -endpoint 'https://api.au.sumologic.com' -accessid $env:SAI_LIVE -accesskey $env:SAK_LIVE   
```

# using multiple sessions
use sumo_session param to specify a session.

```
$from_folder=(get-PersonalFolder -sumo_session $dev).children | where {$_.name -match 'Use Case Examples'}
$to_folder=(get-PersonalFolder -sumo_session $live).children | where {$_.name -match 'LiveFolder'}
get-ExportContent -id $from_folder.id -sumo_session $dev |  ConvertTo-Json -Depth 100 | Out-File -FilePath ./data/export.json
start-ContentImportJob -folderId $to_folder.id -contentJSON (gc -Path ./data/export.json -Raw) -overwrite 'true' -sumo_session $live
```