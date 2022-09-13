
param ([string]$output = "object", $endpoint='au')

$sumo=new-contentsession -endpoint $endpoint

$users = Get-Users
$keys = Get-AccessKey   

$keymap = @{}

foreach ($key in $keys) {
    $current = $key | convertto-json -depth 10 | convertfrom-json -depth 10
    $current | Add-Member -MemberType NoteProperty -Name 'email' -Value (($users | where { $_.id -eq $current.createdBy }).email)
    $current | Add-Member -MemberType NoteProperty -Name 'userIsActive' -Value (($users | where { $_.id -eq $current.createdBy }).IsActive)
    
    if ($null -eq $current.email ) {
        $current.email="None"
        $current.userIsActive=$false
    }

    $keymap[$current.id] =  $current

}


if ($output -eq 'json') {
    write-output ($keymap | convertto-json -depth 10)
} elseif ($output -eq 'object') {
    write-output $keymap
} 
