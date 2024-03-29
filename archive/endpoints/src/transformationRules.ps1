# auto generated by srcgen transformationRules 12/8/2021 1:02:03 PM 


<#
    .DESCRIPTION
    /v1/transformationRules,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-TransformationRules {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "transformationRules" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/transformationRules,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-TransformationRule {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "transformationRules" -method POST -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/transformationRules/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Remove-TransformationRuleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "transformationRules/$id" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/transformationRules/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-TransformationRuleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "transformationRules/$id" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/transformationRules/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-TransformationRuleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "transformationRules/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
}

