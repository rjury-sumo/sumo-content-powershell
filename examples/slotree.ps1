$slos = Get-SloTree 

$output = 'json'
if ($output -eq 'json') {
    Write-Output $slos | convertto-json -Depth 10
} else {
    write-output $slos | convertto-csv
}