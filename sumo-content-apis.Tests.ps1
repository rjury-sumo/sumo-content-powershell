BeforeAll {
    foreach ($f in dir ./sumo-content-powershell/*.ps1) { if ($f.name -inotmatch 'build') {. $f.fullname}  }
    if ($env:SUMO_ACCESS_ID -notmatch '[a-zA-Z1-9]{14}') { write-error "SUMO_ACCESS_ID or KEY is not set"; exit }
    if ($env:SUMO_ACCESS_KEY -notmatch '[a-zA-Z1-9]{64}') { write-error "SUMO_ACCESS_ID or KEY is not set"; exit }
    $endpoint = 'https://api.au.sumologic.com'

    $sumo = new-ContentSession -endpoint $endpoint    
    $sumo_admin = new-ContentSession -endpoint $endpoint  -isadminmode 'true'

    $resource = @{}

    foreach ($f in dir ./library/*.json ) {
        $json = Get-Content -Path "$($f.FullName)" 
        $name = $f.Name -replace "\.json",""
        $resource["$name"] = $json | convertfrom-json -depth 100
    }

}

Describe "sumo-content-apis-tests" {

    Context "environment" -Tag "env" {

        It "endpoint format" {
            $endpoint | Should -Match 'https:..[^ ]+.sumologic.com'
        }

    }

    Context "connection" -Tag "connection" {

        It "endpoint"  {
            $sumo.endpoint | Should -Be $endpoint
        }

        It "websession"  {
            $sumo.WebSession.gettype().name | Should -Be 'WebRequestSession'
        }

        It "websesssion has valid personal folder property" {
            $sumo.PersonalFolderId | Should -Match '^[0-9A-F]{16}$'
        }
    }

    Context "functions" -tag "functions" {

        It "getquerystring returns urlencoded string"  {
            getQueryString @{ 'a' = 'b'; 'c' = 'a b c ' } | Should -Be 'a=b&c=a+b+c+'
        }

        It "copy-proppy returns cloned object with replace text in category property" -Tag 'unit' {
            (copy-proppy -to $resource['source'] -replace_props @('category') -replace_pattern 'test' -with 'prod').category | Should -Be 'prod/labs/default'
        }

        It "source2 property returns cloned 'to' object with copied name property from 'from'" -Tag "unit" {
            
            (copy-proppy -from $resource['source'] -to $resource['source2'] -props @("name") ).name | Should -Be $resource['source'].name
        }

        It "convertSumoDecimalContentIdToHexId converts decimal to 16 digit hex string" -Tag "unit" {
            convertSumoDecimalContentIdToHexId -id 14487342 | Should -Be '0000000000DD0F2E'
        }
    }

    Context "folders" -tag "folders" {


        It "get-PersonalFolder"  {
            (get-personalfolder).name | Should -Match 'Personal|[rR]ick'
        }

        It "get-folderContent global defaults to global"  {
            ((get-folderContent) | where {$_.name -match 'Personal|[rR]ick'}).count | Should -BeGreaterOrEqual 1

        }

        It "get-folderContent global defaults to global"  {
            (get-folderContent -type global)[0].itemType | Should -Be 'Folder'
            ((get-folderContent -type global -sumo_session $sumo ) | where {$_.name -match 'Personal|[rR]ick'}).count  | Should -BeGreaterOrEqual 1

        }

        It "get-foldercontent adminRecommended returns adminRecommended"  {
            $f = get-folder -id (get-PersonalFolder -sumo_session $sumo).id
            $f.id| Should -Match '[A-F0-9]{16}'
            $f.itemType | Should -Be 'Folder'
        }

    }

    Context "content" -tag "content" {

        It "get-contentpath returns path for personalfolder"  {
            get-contentpath -id (get-personalfolder)[0].id | Should -match '/library/Users/.+'
        }
    }


    Context "collectors" -tag "collectors" {

        It "get-collectorByName -Name 'test' returns test collector"  {
            (get-collectorByName -Name 'test' ).name | Should -Be 'test'
        }
    }

    Context "sources" -tag "sources" {
        It "get-sources by id returns list of sources" -tag "sources" {
            (get-sources -id (get-collectorByName -Name 'test' ).id)[0].sourceType | Should -Be 'HTTP'
        }
    }

    Context "dashboards" -tag "dashboards" {

        It "return clone of 'to' dashboard copying properties from 'from' object"  {
            $d1 = $resource['dashboard']
            $d1.title = 'old'
            $d2 = $resource['dashboard']
            
            (copy-proppy -from $d1 -to $d2 -props @('title') ).title | Should -match 'old'
        }

        It "return clone of 'to' dashboard copying title from 'from' object, and replace a string"  {
            $d1 = $resource['dashboard']
            $d1.title = 'A BB C'
            $d2 = $resource['dashboard']
            
            (copy-proppy -from $d1 -to $d2 -props @('title') -replace_props @('title') -replace_pattern 'BB' -with 'XX' ).title | Should -match 'A XX C'
        }

        It "return clone of 'to' dashboard copying title from 'from' object, and replace a string using text mode"  {
            $d1 = $resource['dashboard']
            $d1.title = 'A B|B C'
            $d2 = $resource['dashboard']
            
            (copy-proppy -from $d1 -to $d2 -props @('title') -replace_props @('title') -replace_pattern 'B|B' -with 'XX' -replace_mode 'text' ).title | Should -match 'A XX C'
        }

        It "return clone of 'to' dashboard copying title from 'from' object, and replace a string using text mode"  {
            $d1 = $resource['dashboard']
            $d1.title = 'A B|B C'
            $d2 = $resource['dashboard']
            
            (copy-proppy -from $d1 -to $d2 -props @('title') -replace_props @('title') -replace_pattern 'B|B' -with 'XX' -replace_mode 'text' ).title | Should -match 'A XX C'
        }

        It "return clone of 'to' dashboard by replace panels object query in JSON mode"  {
            $d1 = $resource['dashboardapi-exported']
            (copy-proppy -to $d1 -replace_props @('panels') -replace_pattern 'latitude' -with 'XX' ).panels[0].queries.queryString | Should -Be 'ip ip_address=* | count by ip_address | lookup XX, longitude, country_name from geo://location on ip=ip_address'
        }
    }

    Context "searchjob" -tag "searchjob" {

        It "get-epochDate -epochDate '04/05/2021 12:26:00' -format 'MM/dd/yyyy HH:mm:ss' returns 1617582360000"  {
            get-epochDate -epochDate '04/05/2021 12:26:00'  -format 'MM/dd/yyyy HH:mm:ss'| Should -Be '1617582360000'
        }

        It "get-epochDate retuns ms same as get-date to utc epoch" {
           get-epochDate | Should -Be (([int][double]::Parse((Get-Date (get-date).touniversaltime() -UFormat %s))) * 1000)
           
        }

        It "get-epochDate -epochDate '04/05/2021 12:26:00' auto returns 1617582360000"  {
            get-epochDate -epochDate '04/05/2021 12:26:00' -format 'auto' | Should -Be '1617582360000'
        }

        It "get-DateStringFromEpoch  -epoch 1620176608000 returns 05/05/2021 13:03:28" {
            get-DateStringFromEpoch  -epoch 1620176608000 | Should -Be '05/05/2021 13:03:28'
        }

        It "get-timeslices returns valid timeslice array" {
            $sample = '[{"start":1617537600000,"startString":"04/05/2021 00:00:00","intervalms":3600000,"end":1617541200000,"endString":"04/05/2021 01:00:00"},{"start":1617541200000,"startString":"04/05/2021 01:00:00","intervalms":3600000,"end":1617544800000,"endString":"04/05/2021 02:00:00"}]' | ConvertFrom-Json
            $ts = (get-timeslices -start '04/05/2021 00:00:00' -end '04/05/2021 02:00:00' | convertto-json | ConvertFrom-Json ) 
            (Compare-Object -ReferenceObject $sample -DifferenceObject $ts ).count  | Should -Be 0

        }
    }

    Context "heirarchies" -tag "hierarchies" {
        It "get awso name should be 'AWS Observability'" {
            (Get-hierarchies | where {$_.name -eq 'AWS Observability'}).name | Should -Be 'AWS Observability'

        }
    }

    Context "heirarchies" -tag "hierarchies" {
        It "get hierarchy by id returns a hierarchy" {
            $id = (Get-hierarchies | where {$_.name -eq 'AWS Observability'}).id
            (Get-hierarchyById -id $id ).name | Should -Be 'AWS Observability'
        }
    }

}