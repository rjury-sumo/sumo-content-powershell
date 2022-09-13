# entities/hierarchies API

<#
    .DESCRIPTION
    /v1/entities/hierarchies,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>

function Get-hierarchies {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "entities/hierarchies" -method GET -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/entities/hierarchies,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
function New-hierarchy {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$body
    )
    return (invoke-sumo -path "entities/hierarchies" -method POST -session $sumo_session -v 'v1' -body $body )
}
 
function Remove-hierarchyById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "entities/hierarchies/$id" -method DELETE -session $sumo_session -v 'v1')
}
 
<#
     .DESCRIPTION
     /v1/entities/hierarchies/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
function Get-hierarchyById {
 
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory = $True)]$id
    )
    return (invoke-sumo -path "entities/hierarchies/$id" -method GET -session $sumo_session -v 'v1')
}
 
 