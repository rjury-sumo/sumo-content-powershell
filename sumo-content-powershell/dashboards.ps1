# auto generated by srcgen dashboards 11/17/2020 2:22:05 PM 


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
     return (invoke-sumo -path "dashboards" -method POST -session $sumo_session -v 'v2' -body $body )
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
 
 
 function Remove-DashboardById {
 
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
     return (invoke-sumo -path "dashboards/$id" -method PUT -session $sumo_session -v 'v2' -body $body )
 }
 
 


<#
    .DESCRIPTION
    undocumented api to map content id to dashboard id.
    /v2/dashboard/contentId,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER id
    id for get. note this is a url id string e.g Tfj7djZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8 not a content id format.

    .EXAMPLE
    Get-DashboardById -id Tfj7djZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8 -sumo_session $be 

    .OUTPUTS
    PSCustomObject.
#>


function Get-DashboardContentIdById {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     $decimalid = (invoke-sumo -path "dashboard/contentId/$id" -method GET -session $sumo_session -v 'v1alpha')
     return (convertSumoDecimalContentIdToHexId $decimalid )
 }

 <#
    .DESCRIPTION
    substitute all strings matching a regular expression in panels with a new string.

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER pattern
    the regular expression pattern that we are going to match in each panel query.

    .PARAMETER replacewith
    the string to replace the matching pattern with.

    .EXAMPLE
    Get-DashboardById -id Tfj7djZozne6odId5iT8uONiSHtITxRCbhsXNEJ3mtvUxcChTdRHCaIQNsd8 -sumo_session $be 

    .OUTPUTS
    PSCustomObject. A new dashboard object with substitutions.
#>
 function Edit-DashboardPanelQueries {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$dashboard,
         [parameter(mandatory=$True)][string]$pattern,
         [parameter(mandatory=$True)][string]$replacewith

     )

     if ($dashboard.panels) {

        # make a fresh dashboard so we don't trash the origional one in memory.
        $newdash = $dashboard | convertto-json -depth 100 | ConvertFrom-Json -Depth 100

         $p=-1
        foreach ($panel in $dashboard.panels) {
            $p = $p +1
            $q = -1
            $changes = 0
            foreach ($query in $panel.queries) {
                $q = $q + 1
                $query_instance = $query.queryString
                        if ($query_instance -match $pattern) {
                            Write-Verbose "matching panel: $p, query $q replacement: $pattern in $query_instance`n"
                            $changes = $changes + 1
                            $newdash.panels[$p].queries[$q].queryString = $query_instance -replace  $pattern,$replacewith
                }
            }
        }
        Write-Verbose "made $changes changes in $($p + 1) panels in $($q +1 ) queries found."
        return $newdash 
     } else {
         Write-Error "Dashboard is invalid must be a dashboard object with panels attribute."
     }
 }