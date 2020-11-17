<#
    .DESCRIPTION
    get /v1/ingestBudgets

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function get-ingestBudgets {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $v = "v2"
        
    )
    return (invoke-sumo -path "ingestBudgets" -session $sumo_session -v $v)
}