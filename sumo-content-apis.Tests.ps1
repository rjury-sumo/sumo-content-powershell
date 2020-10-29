BeforeAll {
    if ($env:SUMO_ACCESS_ID -notmatch '[a-zA-Z1-9]{14}') { write-error "SUMO_ACCESS_ID or KEY is not set"; exit }
    if ($env:SUMO_ACCESS_KEY -notmatch '[a-zA-Z1-9]{64}') { write-error "SUMO_ACCESS_ID or KEY is not set"; exit }
    $endpoint = 'https://api.au.sumologic.com'

    $sumo = new-ContentSession -endpoint $endpoint    
    $sumo_admin =  $sumo = new-ContentSession -endpoint $endpoint  -isadminmode 'true'

    $resource = @{}
$resource['source'] = @'
{
    "id": 123456789,
    "name": "rick-test-default",
    "category": "test/labs/default",
    "automaticDateParsing": true,
    "multilineProcessingEnabled": true,
    "useAutolineMatching": true,
    "forceTimeZone": false,
    "filters": [],
    "cutoffTimestamp": 0,
    "encoding": "UTF-8",
    "fields": {},
    "messagePerRequest": false,
    "url": "https://collectors.au.sumologic.com/receiver/v1/http/abcdefg==",
    "sourceType": "HTTP",
    "alive": true
  }
'@

$resource['source2'] = @'
{
    "id": 987654321,
    "name": "rick-test-2",
    "category": "test/labs/2",
    "automaticDateParsing": true,
    "multilineProcessingEnabled": false,
    "useAutolineMatching": true,
    "forceTimeZone": false,
    "filters": [],
    "cutoffTimestamp": 0,
    "encoding": "UTF-8",
    "fields": {},
    "messagePerRequest": true,
    "url": "https://collectors.au.sumologic.com/receiver/v1/http/abcdefg==",
    "sourceType": "HTTP",
    "alive": true
  }
'@

$resource['personalFolder'] = @'
{                                                                                                                                                                                          "createdAt": "2020-03-15T21:53:33Z",                                                                                                                                                     "createdBy": "000000000057B6D2",                                                                                                                                                         "modifiedAt": "2020-03-15T21:53:33Z",                                                                                                                                                  
  "modifiedBy": "000000000057B6D2",
  "id": "00000000005E5403",
  "name": "Personal",
  "itemType": "Folder",
  "parentId": "0000000000000000",
  "permissions": [
    "View"
  ],
  "description": "My saved searches and dashboards",
  "children": [
    {
      "createdAt": "2020-04-16T03:35:59Z",
      "createdBy": "000000000057B6D2",
      "modifiedAt": "2020-04-16T03:35:59Z",
      "modifiedBy": "000000000057B6D2",
      "id": "0000000000619446",
      "name": "test",
      "itemType": "Folder",
      "parentId": "00000000005E5403",
      "permissions": "GrantEdit View Edit GrantView GrantManage Manage"
    },
    {
      "createdAt": "2020-04-14T05:06:40Z",
      "createdBy": "000000000057B6D2",
      "modifiedAt": "2020-04-14T05:06:40Z",
      "modifiedBy": "000000000057B6D2",
      "id": "000000000060114D",
      "name": "test dashboard",
      "itemType": "Report",
      "parentId": "00000000005E5403",
      "permissions": "GrantEdit View Edit GrantView GrantManage Manage"
    }
  ]
}
'@

    foreach ($f in dir ./Library/*.json ) {
        $json = Get-Content -Path "$($f.FullName)" 
        $name = $f.Name -replace "\.json",""
        $resource["$name"] = $json | convertfrom-json  -depth 10
    }

}

Describe "sumo-content-apis-tests" {

    Context "environment" -Tag "env" {

        It "acceptance test 3" -Tag "integration" {
            $endpoint | Should -Match 'https:..[^ ]+.sumologic.com'
        }

    }

    Context "connection" {

        It "endpoint" -tag 'integration' {
            $sumo.endpoint | Should -Be $endpoint
        }

        It "websession" -Tag "integration" {
            $sumo.WebSession.gettype().name | Should -Be 'WebRequestSession'
        }
    }

    Context "functions" {

        It "getquerystring returns urlencoded string" -tag 'unit' {
            getQueryString @{ 'a' = 'b'; 'c' = 'a b c ' } | Should -Be 'a=b&c=a+b+c+'
        }

        It "copy-proppy replaces text" -Tag "unit" {
            
            $r = $resource['source'] | convertfrom-json -depth 10
            (copy-proppy -to $r -replace_pattern 'test' -with 'prod').category | Should -Be 'prod/labs/default'
        }

        It "source2 property validation" -Tag "unit" {
            
            $r = $resource['source'] | convertfrom-json -depth 10
            $r2 = $resource['source2'] | convertfrom-json -depth 10        
        
            (copy-proppy -from $r1 to $r2 -props @("name")).name | Should -Be $resource['source'].name
        }
    }

    Context "folders" {


        It "get-PersonalFolder" -tag 'integration' {
            (get-personalfolder).name | Should -Match 'Personal|[rR]ick'
        }

        It "get-folderContent global defaults to global" -tag 'integration' {
            (get-folderContent).name | Should -Match 'Personal|[rR]ick'

        }

        It "get-folderContent global defaults to global" -tag 'integration,folders' {
            (get-folderContent -type global)[0].itemType | Should -Be 'Folder'
            (get-folderContent -type global).name | Should -Match 'Personal|[rR]ick'

        }

        It "get-foldercontent adminRecommended returns adminRecommended" -tag 'integration,folders' {
            $f = get-folder -id (get-PersonalFolder).id
            $f.id| Should -Match '[A-F0-9]{16}'
            $f.itemType | Should -Be 'Folder'
        }

        

    }

    Context "content" {

        It "get-contentpath returns path for personalfolder" -Tag "integration" {
            get-contentpath -id (get-personalfolder)[0].id | Should -match '/Library/Users/.+'
        }
    }
}