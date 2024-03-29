# auto generated by srcgen dynamicParsingRules 12/8/2021 1:02:02 PM 


<#
    .DESCRIPTION
    /v1/dynamicParsingRules,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-DynamicParsingRules {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "dynamicParsingRules" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/dynamicParsingRules,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-DynamicParsingRules {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "dynamicParsingRules" -method POST -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/dynamicParsingRules/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Remove-DynamicParsingRulesById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "dynamicParsingRules/$id" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/dynamicParsingRules/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-DynamicParsingRulesById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "dynamicParsingRules/$id" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/dynamicParsingRules/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-DynamicParsingRulesById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "dynamicParsingRules/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
}

