
<#
    .DESCRIPTION
    get /collectors/[collectorId]/sources

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-sources {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)] $id
        
    )
    return (invoke-sumo -path "collectors/$id/sources" -session $sumo_session -v $v ).sources
}



<#
    .DESCRIPTION
    get /collectors/[collectorId]/sources/[sourceId]

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-sourceById {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)] $id,
        [parameter(Mandatory = $true)] $sourceid

        
    )
    return (invoke-sumo -path "collectors/$id/sources/$sourceid" -session $sumo_session -v $v ).source
}
