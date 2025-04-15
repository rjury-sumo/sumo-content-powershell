#new-ContentSession -endpoint 'au'
# all the monitors
$monitors = Get-MonitorsSearch -query 'type:Monitor'
$log_monitors = $monitors  | where { $_.item.monitorType -eq 'Logs' }

$monitors_formatted = New-Object System.Collections.Generic.List[System.Object]
foreach ($monitor in $log_monitors) {
    $id = "$($monitor.item.id)"
    # write-host "add item $id"
    $m = @{
        'Name' = $monitor.item.name;
        'Description' = $monitor.item.description;
        'monitorType' = $monitor.item.monitorType;
        'id' = $id
        'Path' = $monitor.path;
        'runAs' = $monitor.item.runAs;
        'created' = $monitor.item.createdAt;
        'updated' = $monitor.item.modifiedAt;
        'log_query' = $monitor.item.queries[0].query;
    }
    $monitors_formatted.add($m)
   
}

Write-Output ($monitors_formatted | ConvertTo-Json -Depth 10)
#Write-Output ($monitors_formatted | ConvertTo-Csv)