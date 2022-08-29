<#
    .DESCRIPTION
    /v2/content/{id}/permissions,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>

function Get-ContentPermissionsById {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $false)]$explicitOnly = $false       
    )
    $params = @{'explicitOnly' = $explicitOnly}
    return (invoke-sumo -path "content/$id/permissions" -method GET -session $sumo_session -v 'v2' -params $params)
}
 
<#
     .DESCRIPTION
     /v2/content/{id}/permissions/add,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-ContentPermissionsAddById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "content/$id/permissions/add" -method PUT -session $sumo_session -v 'v2' -body $body )
}
 
<#
     .DESCRIPTION
     /v2/content/{id}/permissions/remove,put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
function Set-ContentPermissionsRemoveById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "content/$id/permissions/remove" -method PUT -session $sumo_session -v 'v2' -body $body )
}
 
