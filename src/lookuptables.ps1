<#
    .DESCRIPTION
    get /v1/lookupTables

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-lookupTables {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "lookupTables" -session $sumo_session -v $v).data
}