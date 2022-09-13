# path for lookups will be personalfolder/lookups and we assume we already created this folder with admin manage and global read permission
$lookupName = 'slos_config'
$lookupParent = (get-PersonalFolder).id

# test if the lookup table already exists
$existinglookup = (Get-ContentFolderById -id (get-PersonalFolder).id).children | where { $_.name -eq $lookupName }

if ( $existinglookup) {
    # we can go ahead and import to update
    $id = $existinglookup.id
    write-host "lookup table already exists at id $id"
}
else {
    # we need to create it
    write-host "Creating new lookups since it does not exist."
    $newid = New-LookupTable -name $lookupName -parentFolderId $lookupParent -description 'A lookup table of slo config' -primaryKeys @($key) -columns $lookupColumns #-Verbose -dryrun $true
}

write-host "getting list of SLOs from API..."
$slotree = Get-SloTree  | where { $_.contentType -eq 'Slo' } 

# the key column for the lookup table
$key = 'id'

# where is tmp (can vary on pwsh vs windows)
$tempPath = (New-TemporaryFile).fullName | split-path -Parent
$csvPath = "$tempPath/sumo_slo_lookup.csv"

# this is a custom csv fomatter since some of the fields contain embedded objects that just export as System.Object[]
$output = @()

foreach ($slo in $slotree) {
    # construct a custom object because some fields contain embedded objects that don't export csv properly
    $row = $slo | Select-Object -Property id,name,description,version
    $row | Add-Member -MemberType NoteProperty -Name "createdat" -value $slo.createdat ;
    $row | Add-Member -MemberType NoteProperty -Name "createdby" -value $slo.createdby ;
    $row | Add-Member -MemberType NoteProperty -Name "modifiedat" -value $slo.modifiedat ;
    $row | Add-Member -MemberType NoteProperty -Name "modifiedby" -value $slo.modifiedby ;
    $row | Add-Member -MemberType NoteProperty -Name "parentid" -value $slo.parentid ;
    $row | Add-Member -MemberType NoteProperty -Name "contenttype" -value $slo.contenttype ;
    $row | Add-Member -MemberType NoteProperty -Name "type" -value $slo.type ;
    $row | Add-Member -MemberType NoteProperty -Name "issystem" -value $slo.issystem ;
    $row | Add-Member -MemberType NoteProperty -Name "ismutable" -value $slo.ismutable ;
    $row | Add-Member -MemberType NoteProperty -Name "permissions" -value ($slo.permissions | convertto-json -depth 10 -compress) ;
    $row | Add-Member -MemberType NoteProperty -Name "signaltype" -value $slo.signaltype ;
    $row | Add-Member -MemberType NoteProperty -Name "compliance" -value ($slo.compliance | convertto-json -depth 10 -compress) ;
    $row | Add-Member -MemberType NoteProperty -Name "indicator" -value ($slo.indicator | convertto-json -depth 10 -compress) ;
    $row | Add-Member -MemberType NoteProperty -Name "service" -value $slo.service ;
    $row | Add-Member -MemberType NoteProperty -Name "application" -value $slo.application ;
    $row | Add-Member -MemberType NoteProperty -Name "sloversion" -value $slo.sloversion ;
    $row | Add-Member -MemberType NoteProperty -Name "path" -value $slo.path ;

    $output += $row
}

write-host "output slo csv to: $csvPath"
$output | convertto-csv | out-file -FilePath "$csvPath" -Force

$job = (Set-LookupTableFromCsv -id 0000000000B6D3DF -filepath $csvPath).id
write-host "Started lookup table update job $job "

#Write-Output $output


