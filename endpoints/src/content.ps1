# auto generated by srcgen content 11/16/2020 5:28:46 PM 


<#
    .DESCRIPTION
    /v2/content/folders,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ContentFolders {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/folders" -method POST -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/folders/adminRecommended,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersAdminRecommended {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "content/folders/adminRecommended" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/adminRecommended/{jobId}/result,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersAdminRecommendedResultById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/folders/adminRecommended/$jobId/result" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/adminRecommended/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersAdminRecommendedStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/folders/adminRecommended/$jobId/status" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/global,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersGlobal {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "content/folders/global" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/global/{jobId}/result,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersGlobalResultById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/folders/global/$jobId/result" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/global/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersGlobalStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/folders/global/$jobId/status" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/personal,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersPersonal {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "content/folders/personal" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/{folderId}/import,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER folderId
    folderId for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ContentFoldersImportById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$folderId,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/folders/$folderId/import" -method POST -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/folders/{folderId}/import/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER folderId
    folderId for get

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersImportStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$folderId,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/folders/$folderId/import/$jobId/status" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/{id},get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentFoldersById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "content/folders/$id" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/folders/{id},put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-ContentFoldersById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/folders/$id" -method PUT -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/path,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentPath {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session
    )
    return (invoke-sumo -path "content/path" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{contentId}/export/{jobId}/result,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER contentId
    contentId for get

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentExportResultById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$contentId,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/$contentId/export/$jobId/result" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{contentId}/export/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER contentId
    contentId for get

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentExportStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$contentId,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/$contentId/export/$jobId/status" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{contentId}/path,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER contentId
    contentId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentPathById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$contentId
    )
    return (invoke-sumo -path "content/$contentId/path" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{id}/copy,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ContentCopyById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/$id/copy" -method POST -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/{id}/copy/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentCopyStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/$id/copy/$jobId/status" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{id}/delete,delete

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for delete

    .OUTPUTS
    PSCustomObject.
#>


function Delete-ContentDeleteById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "content/$id/delete" -method DELETE -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{id}/delete/{jobId}/status,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .PARAMETER jobId
    jobId for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentDeleteStatusById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$jobId
    )
    return (invoke-sumo -path "content/$id/delete/$jobId/status" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{id}/export,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ContentExportById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/$id/export" -method POST -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/{id}/move,post

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for post

    .PARAMETER body
    PSCustomObject body for post

    .OUTPUTS
    PSCustomObject.
#>


function New-ContentMoveById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/$id/move" -method POST -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/{id}/permissions,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get

    .OUTPUTS
    PSCustomObject.
#>


function Get-ContentPermissionsById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id
    )
    return (invoke-sumo -path "content/$id/permissions" -method GET -session $sumo_session -v 'v2')
}

<#
    .DESCRIPTION
    /v2/content/{id}/permissions/add,put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-ContentPermissionsAddById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/$id/permissions/add" -method PUT -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

<#
    .DESCRIPTION
    /v2/content/{id}/permissions/remove,put

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for put

    .PARAMETER body
    PSCustomObject body for put

    .OUTPUTS
    PSCustomObject.
#>


function Set-ContentPermissionsRemoveById {

   Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(mandatory=$True)]$id,
        [parameter(mandatory=$True)]$body
    )
    return (invoke-sumo -path "content/$id/permissions/remove" -method PUT -session $sumo_session -v 'v2' -body ($body | ConvertTo-Json -depth 10) )
}

