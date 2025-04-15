

# exports the folder api recursing child folder nodes, until there are none left
function Get-ContentTree {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory = $False)]$id,  # of the root folder to start search
         #[parameter(Mandatory = $False)][Array]$child_items = @(),
         [parameter(Mandatory = $False)][string]$path,  # the path passed down recursively from root
         [parameter(Mandatory = $False)][string]$typeMatches = '.*', # regex for types
         [parameter(Mandatory = $False)][string]$nameMatches = '.*' # regex for types
     )

     $child_items = @()

     if ($id -eq $null) {
        $node = get-PersonalFolder
     } else {
        $node = get-Folder -id $id
     }
    
    # shortcut was corrupting paths due to recursion bug. will fix later
    # If ($path -eq $null) {
        # root node get a path then infer it
        $path=get-ContentPath -id $node.id 
    # } else {
    #    $path = "$path/$($node.name)"
    # }

    Write-Host "Checking Path: $path Node: $($node.id) children: $($node.children.count) name $($node.name)"

    if ( $node.children.count -gt 0) {
        foreach ($child in $node.children ) {
            # there is a recursion bug in this script so using actual path
            
            # add a custom inferred path so don't need to get item path api every time
            $child | Add-Member -MemberType NoteProperty -Name path -Value "$path/$($child.name)" #get-ContentPath -id
            if (($child.itemType -match $typeMatches) -and ($child.name -match $nameMatches) ){ # 
                $child_items += $child
                Write-Verbose "Found item: $($child.itemType) - $($child.name)"
            } else {
                Write-Verbose "skip item: $typematches -match $($child.itemType) $nameMatches -match $($child.name)"
            }
            if ($child.itemType -eq "Folder" ) {
                write-verbose "get child folder: $child.id"
                $child_items += Get-ContentTree -id $child.id -sumo_session $sumo_session -path $child.path -nameMatches $nameMatches -typeMatches $typeMatches
            } 
        }
    }
    return [Array]$child_items
}

# search starting with personal folder (null default for id)
#$content_matching_items =  Get-ContentTree -typeMatches 'Dash' 
# write-output ($content_matching_items | convertto-json -depth 10)

# all the  dashboards items in admin mode
[Array]$global_items = @()
$root = get-folderGlobalContent -type global  
foreach ($folder in $root) {
    $global_items += Get-ContentTree -typeMatches 'Dash' -id $folder.id
}

$admin_recommended = get-folderGlobalContent -type adminRecommended  
foreach ($folder in $admin_recommended) {
    $global_items += Get-ContentTree -typeMatches 'Dash' -id $folder.id
}
