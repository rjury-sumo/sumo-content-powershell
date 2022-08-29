# backup various v2 dashboards
# for id use the UI id you see in browser
# note there is no 'get-dasbhards' endpoint for the v2 dashboard api yet :-(

$dashboards_to_backup = @{
    'dash1' = 'abcdefSAM638zzDiGHMRCHMD44xYFnHGEBu4m1BySqFPmh8RPwl9KZl8RoBT';
    'dash2' = 'abcdefkdr2DThyJwBEoYEjXl16rm1ZsYmSvwJ4zzeK2zRLUWfktrwY8WlFunk';
 }

New-Item -Type Directory ./Backups -ErrorAction SilentlyContinue

foreach ($dash in $dashboards_to_backup.keys) {
    # v2 API by UI dash ID
    $filename = ($dash -replace " ", '.') + ".$($dashboards_to_backup[$dash]).json"
    Get-DashboardById -id $dashboards_to_backup[$dash] | ConvertTo-Json -depth 100 | out-file "./backups/$filename"
}

ls -altr ./Backups