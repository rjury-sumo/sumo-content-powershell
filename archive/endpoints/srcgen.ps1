. ./api-gen.ps1

$endpoints = new-sumoEndpointsList
foreach ($api in ($endpoints.api | uniq)) {
    $apiendpoints = select-sumoEndpoint -endpoints (select-sumoEndpoint -endpoints $endpoints -api $api)

    $file = "./src/" + $api + ".ps1"
    write-host "`n`ngenerating for API: $api in: $file`n"

    @('# auto generated by srcgen',$api,(get-date),"`n`n") -join ' ' | Out-File -FilePath $file -Encoding ascii
    foreach ($endpoint in $apiendpoints) {
        write-host $endpoint.name
        new-SumoFunctionBlock -endpoint $endpoint | out-file -FilePath $file -Append -Encoding ascii
    }
}

