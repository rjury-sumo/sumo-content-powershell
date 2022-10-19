<#

    .SYNOPSIS
    Show users older than a lastlogin time or who might be inactive state.

    .DESCRIPTION
    Show users older than a lastlogin time or who might be inactive state.

    .EXAMPLE
    show users older than default of 90d and inactive status only
    ./show.users.ps1 -onlyInactive $True 
    
    .EXAMPLE
    show all users regardless of login date
    ./delete.users.ps1 -days -1 

    #>

param ([string]$output = "simplejson", $days = '90', [string]$include = '.+', [string]$exclude = 'sumosupport', [bool]$onlyInactive = $false)
Write-Host "starting Script at: $((get-date).tostring())"
$users = get-users
$now = get-date
$userslist = $users | Sort-Object -Property lastLoginTimestamp  | where { $_.email -notmatch $exclude -and $_.email -match $include -and (( New-TimeSpan -start $_.lastLoginTimestamp  -End $now ).Days -gt $days) -and ($onlyInactive -eq $False -or $_.isActive -eq $False)  }

write-host "Matched: $($userslist.count) users."
foreach ($user in $userslist) {
    Write-Host "User: $($user.id) $($user.email) active: $($user.isActive.tostring()) lastLoginTiemstamp: $($user.lastLoginTimestamp) was $(( New-TimeSpan -start $user.lastLoginTimestamp  -End $now ).Days) days ago. "
}
