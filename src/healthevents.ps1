
<#
    .DESCRIPTION
    get /v1/healthEvents

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-healthEvents {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "healthEvents" -session $sumo_session -v 'v1')
}
