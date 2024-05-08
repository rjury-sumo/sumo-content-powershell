# get list of apps
```
get-apps
```

# get apps by name
list apps with Cloudtrail in name using a session object.
```
get-apps -sumo_session $be | where {$_.appDefinition.name -match 'Cloudtrail'}  
```

# get app by uuid
Get AWS CloudTrail app and show it as JSON
```
Get-AppById -uuid 'ceb7fac5-1137-4a04-a5b8-2e49190be3d4' -sumo_session $be | convertto-json -depth 100
```

# install an app
Install Log Analysis Quickstart.
Use default name and descriptoin from manifest but add custom params.
```
Install-SumoApp -uuid deadca25-5fa9-4620-812d-dced60b59ff8 -dataSourceValues @{'Log data source' = '_sourcecategory=*' }
```

# install all the default admin apps in a folder in adminrecommended

Assumes _SumoAdmin folder already exists in AdminRecommended and permissions include Manage for current user
```
$install_folder_id = (((get-folderContent -type adminRecommended).children) | where  { $_.name -match '_SumoAdmin' }).id
$adminApps = ($apps | where {  $_.appDefinition.name  -and $_.appManifest.categories -contains 'Sumo Logic'}) 
$adminApps | foreach { Install-SumoApp -uuid $_.appDefinition.uuid -destinationFolderId $install_folder_id -description $_.appDefinition.name }
```
