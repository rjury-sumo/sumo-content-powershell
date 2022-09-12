$slos = Get-SloTree 

$output = 'csv'
if ($output -eq 'json') {
    Write-Output $slos | convertto-json -Depth 10
} else {
    write-output $slos | convertto-csv
}