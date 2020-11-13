BeforeAll {
    . (Get-ChildItem -Recurse 'api-gen.ps1').FullName
    $endpoints = new-sumoEndpointsList

    $endpointsSampleJSON = @'
    [
        {
          "method": "get",
          "name": "/v1/fields,get",
          "uri": "/v1/fields",
          "verb": false,
          "api": "fields",
          "v": "v1",
          "params": []
        },
        {
          "method": "post",
          "name": "/v1/fields,post",
          "uri": "/v1/fields",
          "verb": false,
          "api": "fields",
          "v": "v1",
          "params": []
        },
        {
          "method": "get",
          "name": "/v1/fields/builtin,get",
          "uri": "/v1/fields/builtin",
          "verb": "builtin",
          "api": "fields",
          "v": "v1",
          "params": []
        },
        {
          "method": "get",
          "name": "/v1/fields/builtin/{id},get",
          "uri": "/v1/fields/builtin/{id}",
          "verb": false,
          "api": "fields",
          "v": "v1",
          "params": [
            "id"
          ]
        },
        {
          "method": "get",
          "name": "/v1/fields/dropped,get",
          "uri": "/v1/fields/dropped",
          "verb": "dropped",
          "api": "fields",
          "v": "v1",
          "params": []
        },
        {
          "method": "get",
          "name": "/v1/fields/quota,get",
          "uri": "/v1/fields/quota",
          "verb": "quota",
          "api": "fields",
          "v": "v1",
          "params": []
        },
        {
          "method": "delete",
          "name": "/v1/fields/{id},delete",
          "uri": "/v1/fields/{id}",
          "verb": false,
          "api": "fields",
          "v": "v1",
          "params": [
            "id"
          ]
        },
        {
          "method": "get",
          "name": "/v1/fields/{id},get",
          "uri": "/v1/fields/{id}",
          "verb": false,
          "api": "fields",
          "v": "v1",
          "params": [
            "id"
          ]
        },
        {
          "method": "delete",
          "name": "/v1/fields/{id}/disable,delete",
          "uri": "/v1/fields/{id}/disable",
          "verb": "disable",
          "api": "fields",
          "v": "v1",
          "params": [
            "id"
          ]
        },
        {
          "method": "put",
          "name": "/v1/fields/{id}/enable,put",
          "uri": "/v1/fields/{id}/enable",
          "verb": "enable",
          "api": "fields",
          "v": "v1",
          "params": [
            "id"
          ]
        }
      ]
'@
        $endpointsSample = $endpointsSampleJSON | ConvertFrom-Json
}

Describe "api-gen tests" {

    Context "new-sumoEndpointsList" -Tag "unit" {

        It "new-sumoEndpointsList returns list" {
            $endpoints.count | Should -BeGreaterThan 100
        }

        It "new-sumoEndpointsList [0] has a name" {
            $endpoints[0].name | Should -Match 'v[0-9]/[a-z]+'
        }

        It "new-sumoEndpointsList [0] has a method" {
            $endpoints[0].method | Should -Match '^[a-z]+$'
        }
    }


    Context "tottitlecase" -Tag "unit" {

        It "totitlecase returns UpperCase" {
            toTitleCase 'upperCase' | Should -Be 'UpperCase'
        }

    }

    Context "select-sumoEndpoint" -tag "unit" {
        It "select-sumoEndpoint -method 'get' -api 'fields' -uri 'fields`$' returns /v1/fields,get endpoint" {
            (select-sumoEndpoint -endpoints $endpoints -method 'get' -api 'fields' -uri 'fields$')| convertto-json -depth 10  -compress | Should -be '{"verb":false,"method":"get","api":"fields","params":[],"name":"/v1/fields,get","v":"v1","uri":"/v1/fields"}'
        }
    }

    Context "new-sumoReturnBlock" -tag "unit" {
        It "new-sumoReturnBlock for /v1/fields,get returns     return (invoke-sumo -path `"fields`" -method GET -session $sumo_session -v 'v1').data" {
            new-sumoReturnBlock -endpoint $endpointsSample[0] | Should -Match " +return .invoke-sumo -path .fields. -method GET -session .sumo_session -v 'v1'..data"
        }

        It "new-sumoReturnBlock for /v1/fields/builtin/{id},get returns     return (invoke-sumo -path `"fields/builtin/$id`" -method GET -session $sumo_session -v 'v1')" {
            new-sumoReturnBlock -endpoint $endpointsSample[3] | Should -Match " +return .invoke-sumo -path .fields/builtin/.id. -method GET -session .sumo_session -v 'v1'"
        }
    }

    Context "select-SumoCommentBlock" -tag "unit" {
        It "new-SumoCommentBlock -endpoint $endpointsSample[0] returns uri and params" {
            ((new-SumoCommentBlock -endpoint $endpointsSample[0]) -join '`n')  | Should -match "(?s)\.DESCRIPTION.+/v1/fields,get.+PARAMETER sumo_session.+sumo_session[\r\n\s]+\.OUTPUT"
        }

        It "new-SumoCommentBlock -endpoint $endpointsSample[3] returns uri and params" {
            ((new-SumoCommentBlock -endpoint $endpointsSample[3]) -join '`n')  | Should -match "(?s)\.DESCRIPTION.+/v1/fields/builtin.+PARAMETER sumo_session.+PARAMETER id.+OUTPUT"
        }

        It "new-SumoCommentBlock for put adds body" {
            (new-SumoCommentBlock -endpoint (select-sumoEndpoint -endpoints $endpoints -name 'field' -method put ) ) -match 'body' | Should -Be $true
        }

        It "new-SumoCommentBlock for post adds body" {
            (new-SumoCommentBlock -endpoint (select-sumoEndpoint -endpoints $endpoints -method post )[0] ) -match 'body' | Should -Be $true
        }
        
    }

    Context "new-SumoParamsBlock" -tag "unit" {
        It "new-sumoReturnBlock for post adds body param" {
            (new-SumoParamsBlock -endpoint (select-sumoEndpoint -endpoints $endpoints -method post )[0] ) -match 'body'  | Should -Be $true
        }
    }
}