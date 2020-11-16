# auto generated by srcgen dashboards 11/16/2020 5:28:46 PM 


<#
    .DESCRIPTION
    /v2/dashboards,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-Dashboard {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "dashboards" -method POST -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/dashboards/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Delete-DashboardById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "dashboards/$id" -method DELETE -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/dashboards/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-DashboardById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "dashboards/$id" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/dashboards/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-DashboardById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "dashboards/$id" -method PUT -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

