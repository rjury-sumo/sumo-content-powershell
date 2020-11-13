# auto generated by srcgen roles 11/13/2020 3:29:45 PM 


<#
    .DESCRIPTION
    /v1/roles,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-Role {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "roles" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/roles,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-Role {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "roles" -method POST -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/roles/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Delete-RoleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "roles/$id" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/roles/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-RoleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "roles/$id" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/roles/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-RoleById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "roles/$id" -method PUT -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

<#
    .DESCRIPTION
    /v1/roles/{roleId}/users/{userId},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER roleId
    roleId for delete

    .PARAMETER userId
    userId for delete

    .OUTPUTS
    PSCustomObject.
#>


function Delete-RoleUsersById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$roleId,
        [parameter(mandatory=$True)]$userId
    )
    return (invoke-sumo -path "roles/$roleId/users/$userId" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/roles/{roleId}/users/{userId},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER roleId
    roleId for put

    .PARAMETER userId
    userId for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-RoleUsersById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$roleId,
        [parameter(mandatory=$True)]$userId,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "roles/$roleId/users/$userId" -method PUT -session $sumo_session -v 'v1' -Body ($body | ConvertTo-Json) )
}

