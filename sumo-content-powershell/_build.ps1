Get-Content -Path _core.ps1 | out-file ./sumo-content-powershell.psm1 -Encoding ascii

foreach ($f in dir ./*.ps1) { 
    if ($f.name -notmatch '_' ) {
        "`n######################################################### $($f.name) functions ##############################################################" | out-file ./sumo-content-powershell.psm1 -Encoding ascii -Append
        Get-Content -Path "$($f.fullname)" | out-file ./sumo-content-powershell.psm1 -Encoding ascii -Append
    }
}

"`n`n######################################################### Export Functions ##############################################################" | out-file ./sumo-content-powershell.psm1 -Encoding ascii -Append

$functionstoexport = @()
foreach ($f in get-content ./sumo-content-powershell.psm1 | select-string '^ *function') {
    $export = ($f -replace ' *function ', '' ) -replace ' +{.*', ''
    if ($export -inotmatch '-' ) {
        # it's probably a function
        $type = "Function"
    }
    else {
        # it's probably a commandlet
        $type = 'Cmdlet'
    }
    $export = $export -replace '\(.+', ''
    "#Export-ModuleMember -$type $export" | out-file ./sumo-content-powershell.psm1 -Encoding ascii -Append

    $functionstoexport  = $functionstoexport + "'$export'"
}

write-host "make sure to update the FunctionsToExport list in manifest if new functions are added!"
write-host "`n`nFunctionsToExport = @($($functionstoexport -join ',') )"