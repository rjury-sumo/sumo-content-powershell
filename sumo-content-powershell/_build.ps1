Get-Content -Path _core.ps1 | out-file ./sumologic-content.psm1 -Encoding ascii

foreach ($f in Get-ChildItem ./*.ps1) { 
    if ($f.name -notmatch '_' ) {
        "`n######################################################### $($f.name) functions ##############################################################" | out-file ./sumologic-content.psm1 -Encoding ascii -Append
        Get-Content -Path "$($f.fullname)" | out-file ./sumologic-content.psm1 -Encoding ascii -Append
    }
}

"`n`n######################################################### Export Functions ##############################################################" | out-file ./sumologic-content.psm1 -Encoding ascii -Append

$functionstoexport = @()
foreach ($f in get-content ./sumologic-content.psm1 | select-string '^ *function') {
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
    "#Export-ModuleMember -$type $export" | out-file ./sumologic-content.psm1 -Encoding ascii -Append

    $functionstoexport  = $functionstoexport + "'$export'"
}

write-host "make sure to update the FunctionsToExport list in manifest if new functions are added!"
$FunctionsToExport = "FunctionsToExport = @($($functionstoexport -join ',') )"
$old_manifest = get-content -Path ./sumologic-content.psd1
$old_version = [string]($old_manifest | Select-String 'ModuleVersion')
$version = $old_version -replace "[^0-9\.]",''
$major,$minor,$patch = $version -split '\.'
$patch = [int]$patch + 1
$new_version = "ModuleVersion = '$major.$minor.$patch'"

$new_manifest = (Get-Content -Path ./sumologic-content.psd1 -raw ) -replace "ModuleVersion = '[0-9\.]+'",$new_version
$new_manifest = $new_manifest -replace 'FunctionsToExport =[^\n\r]+',$functionstoexport
$new_manifest | Out-File ./sumologic-content.psd1 -Encoding ascii



