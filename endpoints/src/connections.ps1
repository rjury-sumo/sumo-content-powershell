# auto generated by srcgen connections 11/16/2020 5:28:46 PM 


<#
    .DESCRIPTION
    /v1/connections,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Connections {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "connections" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/connections,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-Connection {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "connections" -method POST -session $sumo_session -v 'v1' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v1/connections/test,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ConnectionTest {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "connections/test" -method POST -session $sumo_session -v 'v1' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v1/connections/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Delete-ConnectionById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "connections/$id" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/connections/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ConnectionById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "connections/$id" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/connections/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-ConnectionById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "connections/$id" -method PUT -session $sumo_session -v 'v1' -body ($body | ConvertTo-Json -depth 10) )
}

