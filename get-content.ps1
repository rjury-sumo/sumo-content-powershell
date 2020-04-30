# powershell functions to export content, and put into terraform format (useful for prototyping content or migration)
Param(
        [parameter(Mandatory=$false)][string] $FolderNameToExport = "Search Audit Custom",
        [parameter(Mandatory=$false)][string] $Parent = "Personal",
        [parameter(Mandatory=$false)][string] $endpoint="https://api.us2.sumologic.com",
        [parameter(Mandatory=$false)][string] $accessid=$env:SUMO_ACCESS_ID_BE,
        [parameter(Mandatory=$false)][string] $accesskey=$env:SUMO_ACCESS_KEY_BE,
        [switch]$isAdminMode
)

$Credential = New-Object System.Management.Automation.PSCredential $accessid, ($accesskey | ConvertTo-SecureString -AsPlainText -Force )

if ($IsAdminMode) { $mode = $True}  else { $mode = $False}

function invoke-sumo {
    param(
        [parameter(Mandatory)][string] $path,
        [parameter()][string] $method = 'GET',
        [parameter()][string] $sumo_endpoint=$endpoint,
        [parameter()][Hashtable] $params
    )
    $uri = (@($sumo_endpoint,'api/v2',$path) -join "/") -replace '//v2','/v2'
    write-verbose "invoke_sumo $uri $method"
    if (($params ) -or ( $mode )) {
        $params['isAdminMode'] = $mode.toString().tolower()
        $r = (Invoke-WebRequest -Uri $uri -method $method -Credential $Credential -SessionVariable webSession -Body $params).Content | convertfrom-json

    } else {
        $r = (Invoke-WebRequest -Uri $uri -method $method -Credential $Credential -SessionVariable webSession).Content | convertfrom-json
    }
    return $r
}

# get personal folder as an object
# most useful bits would be id and children array.
function get-PersonalFolder {
    return invoke-sumo -path "content/folders/personal"
}

# get /v2/content/folders/{id}
function get-Folder {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return invoke-sumo -path "content/folders/$id"
}

function get-ContentByPath {
    Param(
        [parameter(Mandatory=$true)][string] $path 
)
    return invoke-sumo -path "content/path" -params @{ 'path' = $path;}
}

# Get path of an item.
function get-ContentPath {
    Param(
        [parameter(Mandatory=$true)][string] $id 
)
    return invoke-sumo -path "content/$id/path"
}

if ($Parent -eq "Personal") {
    $parent_folder = get-PersonalFolder
} else {
    write-host "exporting only implemented for personal folder. please come back later once this is built!"
    exit
}

$export_id =  ($parent_folder.children | where {$_.ItemType -eq "Folder" -and $_.name -eq $FolderNameToExport}).id


