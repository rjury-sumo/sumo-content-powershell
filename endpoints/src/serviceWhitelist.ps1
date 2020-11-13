# auto generated by srcgen serviceWhitelist 11/13/2020 3:29:45 PM 


<#
    .DESCRIPTION
    /v1/serviceWhitelist/addresses,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ServiceWhitelistAddresse {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "serviceWhitelist/addresses" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/serviceWhitelist/addresses/add,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ServiceWhitelistAddressesAdd {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "serviceWhitelist/addresses/add" -method POST -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/serviceWhitelist/addresses/remove,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ServiceWhitelistAddressesRemove {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "serviceWhitelist/addresses/remove" -method POST -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/serviceWhitelist/disable,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function Reset-ServiceWhitelistDisable {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "serviceWhitelist/disable" -method POST -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/serviceWhitelist/enable,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function Reset-ServiceWhitelistEnable {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "serviceWhitelist/enable" -method POST -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/serviceWhitelist/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ServiceWhitelistStatu {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "serviceWhitelist/status" -method GET -session $sumo_session -v 'v1')
}

