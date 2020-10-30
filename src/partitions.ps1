
<#
    .DESCRIPTION
    get /v1/partitions

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>

function get-Partitions {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
        
    )
    return (invoke-sumo -path "partitions" -session $sumo_session -v 'v1').data
}