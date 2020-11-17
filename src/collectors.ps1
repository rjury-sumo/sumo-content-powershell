<#
    .DESCRIPTION
    get /v1/collectors

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-collectors {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter()][string] $limit = 100,
        [parameter()][string] $offset = 0
        
    )
    return (invoke-sumo -path "collectors" -session $sumo_session -v $v -params @{'limit' = $limit; 'offset' = $offset }).collectors
}


<#
    .DESCRIPTION
    get /collectors/offline

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-offlineCollectors {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "collectors/offline" -session $sumo_session -v $v ).collectors
}

<#
    .DESCRIPTION
    get /v1/collectors/{id}

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-collectorById {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)] $id
        
    )
    return (invoke-sumo -path "collectors/$id" -session $sumo_session -v $v ).collector
}


<#
    .DESCRIPTION
    get /v1/collectors/name/[name]

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>
function get-collectorByName {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1",
        [parameter(Mandatory = $true)][string] $Name
        
    )
    $encodedName = [System.Web.HttpUtility]::UrlEncode($name) 
    return (invoke-sumo -path "collectors/name/$encodedName/" -session $sumo_session -v $v )
}
