
function Get-LogSearchesEstimatedUsage {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "logSearches/estimatedUsage" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 