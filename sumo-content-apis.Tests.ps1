BeforeAll {
    foreach ($f in dir ./src/*.ps1) { . $f.fullname }
    if ($env:SUMO_ACCESS_ID -notmatch '[a-zA-Z1-9]{14}') { write-error "SUMO_ACCESS_ID or KEY is not set"; exit }
    if ($env:SUMO_ACCESS_KEY -notmatch '[a-zA-Z1-9]{64}') { write-error "SUMO_ACCESS_ID or KEY is not set"; exit }
    $endpoint = 'https://api.au.sumologic.com'

    $sumo = new-ContentSession -endpoint $endpoint    
    $sumo_admin =  $sumo = new-ContentSession -endpoint $endpoint  -isadminmode 'true'

    $resource = @{}

    foreach ($f in dir ./Library/*.json ) {
        $json = Get-Content -Path "$($f.FullName)" 
        $name = $f.Name -replace "\.json",""
        $resource["$name"] = $json | convertfrom-json -depth 10
    }

}

Describe "sumo-content-apis-tests" {

    Context "environment" -Tag "env" {

        It "acceptance test 3" {
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
    }

    Context "functions" -tag "functions" {

        It "getquerystring returns urlencoded string"  {
            getQueryString @{ 'a' = 'b'; 'c' = 'a b c ' } | Should -Be 'a=b&c=a+b+c+'
        }

        It "copy-proppy replaces text"  {
            (copy-proppy -to $resource['source'] -replace_pattern 'test' -with 'prod').category | Should -Be 'prod/labs/default'
        }

        It "source2 property validation" -Tag "unit" {
            
            (copy-proppy -from $resource['source'] -to $resource['source2'] -props @("name") ).name | Should -Be $resource['source'].name
        }
    }

    Context "folders" -tag "folders" {


        It "get-PersonalFolder"  {
            (get-personalfolder).name | Should -Match 'Personal|[rR]ick'
        }

        It "get-folderContent global defaults to global"  {
            (get-folderContent).name | Should -Match 'Personal|[rR]ick'

        }

        It "get-folderContent global defaults to global"  {
            (get-folderContent -type global)[0].itemType | Should -Be 'Folder'
            (get-folderContent -type global).name | Should -Match 'Personal|[rR]ick'

        }

        It "get-foldercontent adminRecommended returns adminRecommended"  {
            $f = get-folder -id (get-PersonalFolder).id
            $f.id| Should -Match '[A-F0-9]{16}'
            $f.itemType | Should -Be 'Folder'
        }

        

    }

    Context "content" -tag "content" {

        It "get-contentpath returns path for personalfolder" -Tag "integration" {
            get-contentpath -id (get-personalfolder)[0].id | Should -match '/Library/Users/.+'
        }
    }
}