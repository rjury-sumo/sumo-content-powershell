<#
    .DESCRIPTION
    get /v1/users

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-users {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "users" -session $sumo_session -v 'v1').data
}