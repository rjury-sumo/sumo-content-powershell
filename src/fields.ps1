
<#
    .DESCRIPTION
    get /v1/fields

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-Fields {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "fields" -session $sumo_session -v 'v1').data
}
