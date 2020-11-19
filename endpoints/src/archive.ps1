# auto generated by srcgen archive 11/20/2020 9:17:48 AM 


<#
    .DESCRIPTION
    /v1/archive/jobs/count,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ArchiveJobsCount {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "archive/jobs/count" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/archive/{sourceId}/jobs,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER sourceId
    sourceId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ArchiveJobsById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$sourceId
    )
    return (invoke-sumo -path "archive/$sourceId/jobs" -method GET -session $sumo_session -v 'v1')
}

<#
    .DESCRIPTION
    /v1/archive/{sourceId}/jobs,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER sourceId
    sourceId for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ArchiveJobsById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$sourceId,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "archive/$sourceId/jobs" -method POST -session $sumo_session -v 'v1' -body $body )
}

<#
    .DESCRIPTION
    /v1/archive/{sourceId}/jobs/{id},delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER sourceId
    sourceId for delete

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Remove-ArchiveJobsById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$sourceId,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "archive/$sourceId/jobs/$id" -method DELETE -session $sumo_session -v 'v1')
}

