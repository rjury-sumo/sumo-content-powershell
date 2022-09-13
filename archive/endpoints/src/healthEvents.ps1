# auto generated by srcgen healthEvents 12/8/2021 1:02:02 PM 


<#
    .DESCRIPTION
    /v1/healthEvents,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-HealthEvents {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "healthEvents" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/healthEvents/resources,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-HealthEventResources {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "healthEvents/resources" -method POST -session $sumo_session -v 'v1' -body $body )
}
