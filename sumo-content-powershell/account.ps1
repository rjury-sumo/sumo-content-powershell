<#
    .DESCRIPTION
    /v1/account/status,get
    Get information related to the account's plan, pricing model, expiration and payment status.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-AccountStatus {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "account/status" -method GET -session $sumo_session -v 'v1')
 }

 <#
    .DESCRIPTION
    /v1/account/subdomain,get
    Get the configured subdomain.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>

function Get-AccountSubdomain {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "account/subdomain" -method GET -session $sumo_session -v 'v1')
 }


  <#
    .DESCRIPTION
    /v1/account/usageForecast,get
    Get usage forecast with respect to last number of days specified. If nothing is provided for last number of days, the average of term period will be taken to do the forecast.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>

function Get-AccountUsageForecast {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter()][string] $numberOfDays 
    )

    if ($numberOfDays) {
        return (invoke-sumo -path "account/usageForecast" -method GET -session $sumo_session -v 'v1' -params @{ 'numberOfDays' = $numberOfDays })
    } else {
        return (invoke-sumo -path "account/usageForecast" -method GET -session $sumo_session -v 'v1')
    }
 }


<#
    .DESCRIPTION
    Start a content usage export job

    .PARAMETER startDate
    Start date, without the time, of the usage data to fetch. If no value is provided startDate is used as the start of the subscription.

    .PARAMETER endDate
    End date, without the time, of usage data to fetch. If no value is provided endDate is used as the end of the subscription.

    .PARAMETER groupBy
    specific grouping according to day, week, month. Day is default.

    .PARAMETER reportType
    standard|detailed|childDetailed

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER includeDeploymentCharge
    Default: False 
    Deployment charges will be applied to the returned usages csv if this is set to true and the organization is a part of Sumo Organizations as a child.

    .OUTPUTS
    jobId such as -2107214432225550922
#>
function Start-AccountUsageReport {
    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $false)][string] $startDate,
        [parameter(Mandatory = $false)][string] $endDate,        
        [parameter(Mandatory = $false)][string] $groupBy = 'day', 
        [parameter(Mandatory = $false)][string] $reportType = 'standard', 
        [parameter(Mandatory = $false)][string] $includeDeploymentCharge = 'false'
    )

    $p = @{}
    
    if ( $startDate) {
        $p['startDate'] = $startDate
    }

    if ( $endDate) {
        $p['endDate'] = $endDate
    }

    if ( $groupBy) {
        $p['groupBy'] = $groupBy
    }

    if ( $reportType) {
        $p['reportType'] = $reportType
    }

    if ( $includeDeploymentCharge) {
        $p['includeDeploymentCharge'] = $includeDeploymentCharge
    }

    return ( (invoke-sumo -path "account/usage/report" -method 'POST' -session $sumo_session -body $p -v 'v1').jobId)

}

 <#
    .DESCRIPTION
    /v1/account/usage/report/{jobId}/staus,get
    Get the report download URL and status using Job Id.
    If job is complete the returned object reportDownloadURL will contain the download link.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER jobId
    id from start-AccountUsageReport job

    .OUTPUTS
    PSCustomObject.
#>

function Get-AccountUsageReportJobStatus {

    Param(
        [parameter()][SumoAPISession]$sumo_session = $sumo_session,
        [parameter(Mandatory = $true)][string] $jobId 
    )

        return (invoke-sumo -path "account/usage/report/$jobId/status" -method GET -session $sumo_session -v 'v1')

 }
