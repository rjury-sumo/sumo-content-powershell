# auto generated by srcgen lookupTables 12/8/2021 1:02:02 PM 


<#
    .DESCRIPTION
    /v1/lookupTables,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-LookupTable {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "lookupTables" -method POST -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/lookupTables/jobs/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-LookupTableJobsStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "lookupTables/jobs/$jobId/status" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Remove-LookupTableById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "lookupTables/$id" -method DELETE -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-LookupTableById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "lookupTables/$id" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-LookupTableById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id}/deleteTableRow,put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-LookupTableDeleteTableRowById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/deleteTableRow" -method PUT -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id}/row,put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-LookupTableRowById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/row" -method PUT -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id}/truncate,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-LookupTableTruncateById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/truncate" -method POST -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/lookupTables/{id}/upload,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-LookupTableUploadById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "lookupTables/$id/upload" -method POST -session $sumo_session -v 'v1' -body $body )
}

