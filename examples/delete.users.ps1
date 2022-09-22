<#

    .SYNOPSIS
    Remove users older than a lastlogin time or who might be inactive state.

    .DESCRIPTION
    Remove users older than a lastlogin time or who might be inactive state.
    dryrun is set to $true by default and must set to $False to actually delete a user.
    In realtion to content deletion since deleteContent is not set to true, and no user identifier is specified in transferTo, content from the deleted user is transferred to the executing user.

    .EXAMPLE
    Delete users older than default of 90d and inactive status only
    ./delete.users.ps1 -onlyInactive $True -dryrun $False
    
    .EXAMPLE
    Delete any users with last login time > 180 days ago
    ./delete.users.ps1 -days 180 -dryrun $False

    .EXAMPLE
    Delete users regardless of login time matching a pattern
    ./delete.users.ps1 -days -1 -include 'deleteme' -dryrun $false

    #>

param ([string]$output = "simplejson", $days = '90', [bool]$dryrun = $True, [string]$include = '.+', [string]$exclude = 'sumosupport', [bool]$onlyInactive = $false)
Write-Host "starting Script at: $((get-date).tostring())"
Write-Host "Non default params are:" ($PSBoundParameters | ConvertTo-Json -Depth 10)
$users = get-users

$now = get-date

$usersToDelete = $users | where { $_.email -notmatch $exclude -and $_.email -match $include -and (( New-TimeSpan -start $_.lastLoginTimestamp  -End $now ).Days -gt $days) -and ($onlyInactive -eq $False -or $_.isActive -eq $False) }

write-host "Matched: $($usersToDelete.count) users."
foreach ($user in $usersToDelete) {

    Write-Host "User: $($user.id) $($user.email) active: $($user.isActive.tostring()) lastLoginTiemstamp: $($user.lastLoginTimestamp) was $(( New-TimeSpan -start $user.lastLoginTimestamp  -End $now ).Days) days ago. "
    if ($dryrun) {
        write-host "DRYRUN: User $($user.email) " 
    }
    else {
        Write-Host "DELETING User: $($user.email) " 
        Remove-UserById -id $user.id
    }
}
