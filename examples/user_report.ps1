param ([string]$output = "simpleobject",$session = (new-ContentSession) )

#$sumo=new-contentsession
$users = get-users -sumo_session $session
$roles = get-roles -sumo_session $session

$usermap = @{}
$usermapsimple = New-Object System.Collections.Generic.List[System.Object]

foreach ($u in $users) {
    # get a new user object
    $current = $u | convertto-json -depth 5 | convertfrom-json -depth 5
    Write-Verbose "map user: $($current.email)"

    $current | Add-Member -MemberType NoteProperty -Name 'Capabilities' -Value @{}
    $current | Add-Member -MemberType NoteProperty -Name 'SearchFilters' -Value @()
    $current | Add-Member -MemberType NoteProperty -Name 'SearchFilter' -Value ""
    $current | Add-Member -MemberType NoteProperty -Name 'Roles' -value @()
    $current | Add-Member -MemberType NoteProperty -Name 'RoleList' -value ""
    $current | Add-Member -MemberType NoteProperty -Name 'CapabiltiesList' -Value ""

    foreach ($r in $current.roleIds) {
        Write-Verbose "mapping role: $r"
        $role = $roles | where {$_.id -eq $r}

        # make a distinct list of merged capabilities
        foreach ($c in $role.capabilities) {
                $current.Capabilities[$c] = $c
        }

        # make a distinct list of merged SearchFilters
        if ($role.filterPredicate) {
            $current.SearchFilters += "$($role.filterPredicate)"
        }

        $current.Roles += $role.Name
       
    }

    $current.RoleList = $current.Roles -join ","
    $current.CapabiltiesList = ($current.Capabilities.keys | sort ) -join ','
    $temp = $current.SearchFilters -join ') OR ('
    $current.SearchFilter = "($temp)"

    $usermap[$current.email] =  $current
    $row = [pscustomobject]@{
        "email" = $current.email;
        "firstName" = $current.firstname;
        "lastName" = $current.lastname;
        "Roles" = $current.RoleList;
        "Capabilities" = $current.CapabiltiesList;
        "SearchFilter" = $current.SearchFilter;
        "isActive" = $current.isActive
        "lastLoginTimestamp" = $current.lastLoginTimestamp;
    }
    $usermapsimple += $row
    #if ($output -eq 'simpleobject' ) {write-output 

}

if ($output -eq 'json') {
    write-output ($usermap | convertto-json -depth 10)
} elseif ($output -eq 'object') {
    write-output $usermap
} elseif ($output -eq 'simpleobject') {
   Write-Output $usermapsimple
} elseif ($output -eq 'simplejson') {
    write-output ($usermapsimple | convertto-json -depth 10)
} elseif ($output -eq 'simplecsv') {
    write-output ( $usermapsimple| convertto-json -depth 10 | convertfrom-json -depth 10  | convertto-csv)
}