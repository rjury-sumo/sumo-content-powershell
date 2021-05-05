# auto generated by srcgen accessKeys 11/17/2020 2:22:04 PM 


<#
    .DESCRIPTION
    /v1/accessKeys,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject.
#>


function Get-AccessKeys {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "accessKeys" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-AccessKey {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "accessKeys" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys/personal,get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-AccessKeysPersonal {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session
     )
     return (invoke-sumo -path "accessKeys/personal" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-AccessKeyById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "accessKeys/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/accessKeys/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-AccessKeyById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "accessKeys/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 