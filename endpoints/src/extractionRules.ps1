# auto generated by srcgen extractionRules 11/13/2020 3:29:44 PM 


<#
    .DESCRIPTION
    /v1/extractionRules,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ExtractionRule {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "extractionRules" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/extractionRules,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ExtractionRule {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "extractionRules" -method POST -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/extractionRules/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Delete-ExtractionRuleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "extractionRules/$id" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/extractionRules/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ExtractionRuleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "extractionRules/$id" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/extractionRules/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-ExtractionRuleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "extractionRules/$id" -method PUT -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

