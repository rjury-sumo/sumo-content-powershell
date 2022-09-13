
<#
    .DESCRIPTION
    Get the root folder of Slos Library
    v1/slos/root

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-SlosRootFolder {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "slos/root" -method GET -session $sumo_session -v 'v1' )
 }

 <#
     .DESCRIPTION
     /v1/slos/{id},get
     Get and SLO or SLO Folder by it's id.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Get-SloById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "slos/$id" -method GET -session $sumo_session -v 'v1')
}



 <#
     .DESCRIPTION
     v1/slos/{id}/path,get
     Get path of slo object by id.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-SloPathById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "slos/$id/path" -method GET -session $sumo_session -v 'v1' )
}

<#
    .DESCRIPTION
    Get SlO object by Path.
    v1/slos/path

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-SloByPath {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory = $True)]$path
     )
     return (invoke-sumo -path "slos/path" -method GET -session $sumo_session -v 'v1' -params @{'path' = $path} )
 }

 <#
    .DESCRIPTION
    Recursively return the entire SLO Tree starting at the id node (or root)

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    Id of parent node to start recursion. If empty will start are root SLO folder using Get-SlosRootFolder.

    .PARAMETER slos
    This is used for recursion to pass the parent object

    .PARAMETER childrenProperty
    defaults to $True. Set to false which removes the children property from the output for each node.
    
    .PARAMETER pathProperty
    defaults to $True. For each node a path property is added using Get-SloPathById

    .OUTPUTS
    PSCustomObject.
#>

function Get-SloTree {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory = $False)]$id,
         [parameter(Mandatory = $False)][Array]$slos = @(),
         [parameter(Mandatory = $False)][bool]$childrenProperty = $True,
         [parameter(Mandatory = $False)][bool]$pathProperty = $True
     )

     if ($id -eq $null) {
        $node = Get-SlosRootFolder
     } else {
        $node = Get-SloById -id $id
     }

    if ($pathProperty -eq $True) {
         $node | Add-Member -MemberType NoteProperty -Name path -Value ((Get-SloPathById -id $node.id).path)
    } 

    Write-Verbose "SLO Node: $($node.id) children: $($node.children.count) path $($node.path) slds: $($slos.count)"

    if ($childrenProperty -eq $False) {
        $slos += ($node | Select-Object -ExcludeProperty children) 
    } else {
        $slos += $node    
    }

    if ( $node.children.count -gt 0) {
        foreach ($child in $node.children) {
            $slos += Get-SloTree -id $child.id -sumo_session $sumo_session 
        }
    }
     return [Array]$slos
}