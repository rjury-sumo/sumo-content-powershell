
# /v1/scheduledViews

<#
    .DESCRIPTION
    get /v1/scheduledViews

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-scheduledViews {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "scheduledViews" -session $sumo_session -v 'v1')
}
