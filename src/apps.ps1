
<#
    .DESCRIPTION
    get /v1/apps

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-apps {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v1"
        
    )
    return (invoke-sumo -path "apps" -session $sumo_session -v $v).data
}