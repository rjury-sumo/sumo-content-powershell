# auto generated by srcgen users 11/20/2020 9:17:48 AM 


<#
    .DESCRIPTION
    /v1/users,get

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .PARAMETER limit
    default 100 Limit the number of users returned in the response

    .PARAMETER token
    Continuation token to get the next page of results. A page object with the next continuation token is returned in the response body. Subsequent GET requests should specify the continuation token to get the next page of results. token is set to null when no more pages are left.

    .PARAMETER sortBy
    Sort the list of users by the firstName, lastName, or email field.

    .OUTPUTS
    PSCustomObject.
#>


function Get-Users {

    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter()][string] $limit = 100,
         [parameter(mandatory=$false)][string][ValidateSet('firstName','lastName','email')] $sortBy,
         [parameter()][string] $email,
         [parameter()][string] $token
     )
     $params = @{'limit' = $limit; }
     if ($token) { $params['token'] = $token }
     if ($email) { $params['email'] = $email }
     if ($sortBy) { $params['sortBy'] = $sortBy }     
     return (invoke-sumo -path "users" -method GET -session $sumo_session -v 'v1' -params $params)
 }
 
 <#
     .DESCRIPTION
     /v1/users,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-User {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id},delete
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for delete
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Remove-UserById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id" -method DELETE -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id},get
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for get
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Get-UserById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id" -method GET -session $sumo_session -v 'v1')
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id},put
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-UserById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users/$id" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/email/requestChange,post
     An email with an activation link is sent to the user’s new email address. The user must click the link in the email within seven days to complete the email address change, or the link will expire.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function New-UserEmailRequestChangeById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users/$id/email/requestChange" -method POST -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/mfa/disable,put
     Disable multi-factor authentication for given user.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for put
 
     .PARAMETER body
     PSCustomObject body for put
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-UserMfaDisableById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id,
         [parameter(mandatory=$True)]$body
     )
     return (invoke-sumo -path "users/$id/mfa/disable" -method PUT -session $sumo_session -v 'v1' -body $body )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/password/reset,post
     Reset a user's password.
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Reset-UserPasswordById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id/password/reset" -method POST -session $sumo_session -v 'v1' )
 }
 
 <#
     .DESCRIPTION
     /v1/users/{id}/unlock,post
 
     .PARAMETER sumo_session
     Specify a session, defaults to $sumo_session
 
     .PARAMETER id
     id for post
 
     .PARAMETER body
     PSCustomObject body for post
 
     .OUTPUTS
     PSCustomObject.
 #>
 
 
 function Set-UserUnlockById {
 
    Param(
         [parameter()][SumoAPISession]$sumo_session = $sumo_session,
         [parameter(mandatory=$True)]$id
     )
     return (invoke-sumo -path "users/$id/unlock" -method POST -session $sumo_session -v 'v1' )
 }
 