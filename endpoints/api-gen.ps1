

function new-sumoEndpointsList {
    Param(
        [parameter()][string]$Path = (Get-ChildItem -Recurse 'endpoints.txt').FullName
    )

    [System.Collections.ArrayList]$endpoints = @()

    foreach ($endpoint in (get-Content -path $Path) ) {
        $uri, $method = $endpoint -split ","
        $list = $uri -split "/"
        [System.Collections.ArrayList]$params = @()

        foreach ($l in $list) {
            if ($l -match '\{[^\}]+\}') { $params += ( $l -replace '[^a-z0-9]', '') }
        }

        if ($list.count -gt 3 -and $list[-1] -match '^[a-z]+') { 
            $verb = $list[-1] 
        }
        else { 
            $verb = $false
        }

        $endpoints += @{
            "name"   = ($endpoint | out-string) -replace '\n', ""
            "uri"    = $uri;
            "params" = $params;
            "method" = $method;
            "v"      = ($endpoint | select-string -Pattern  "(v[0-9])").matches[0].value
            "verb"   = $verb;
            "api"    = $api = $list[2]
        }
    }

    return $endpoints
}


<#
    .DESCRIPTION
    return endpoint

    .PARAMETER sumo_session
    Specify a session, defaults to $sumo_session

    .OUTPUTS
    PSCustomObject. returns list
#>
function select-sumoEndpoint {
    Param(
        [parameter(Mandatory=$True)]$endpoints,
        [parameter()][string]$verb = '.',
        [parameter()][string]$uri = '.',
        [parameter()][string]$method = '.',
        [parameter()][string]$api = '.',
        [parameter()][string]$name = '.'
    )

    return ( $endpoints | Where-Object {$_.name -match $name -and $_.api -match $api -and $_.uri -match $uri -and $_.verb -match $verb -and $_.method -match $method })
}

# some gets return wierd collections of objects
function new-sumoReturnBlock {
    Param(
        [parameter(Mandatory = $true)]$endpoint
    )
    $tweaks = @{
        "/v1/fields,get" = "data";
    }

    $block = "    return (invoke-sumo -path `"$($endpoint.uri -replace '^/v[0-9]/','')`" -method $($endpoint.method.toupper()) -session `$sumo_session -v '$($endpoint.v)'"

    foreach ($param in $endpoint.params) {
        $block = $block -replace "{$param}", "`$$param"
    }

    if ($endpoint.method -imatch 'put|post') {
        $block = $block + ' -body $body )'
    } else { $block = $block + ')'}

    if ($tweaks["$($endpoint.name)"]) { $block = $block + '.' + $tweaks["$($endpoint.name)"] }

    write-verbose $block
    return $block 
}

function new-SumoCommentBlock {
    Param(
        [parameter(Mandatory = $true)]$endpoint
    )

    $pblock = "    .PARAMETER pname`n    pdescription`n`n"
    $params = "    .PARAMETER sumo_session`n    Specify a session, defaults to `$sumo_session"

    foreach ($param in $endpoint.params ) {
        $params = $params + "`n`n    .PARAMETER $param`n    $param for $($endpoint.method)"
    }

    if ($endpoint.method -match 'post|put') {
        $params = $params + "`n`n    .PARAMETER body`n    PSCustomObject body for $($endpoint.method)"
    }
    
    return "<#`n    .DESCRIPTION`n    $($endpoint.name)" + "`n`n" + $params + "`n`n    .OUTPUTS`n    PSCustomObject.`n#>"
}

function new-SumoParamsBlock {
    Param(
        [parameter(Mandatory = $true)]$endpoint
    )
    $param = '        [parameter()][SumoAPISession]$sumo_session = $sumo_session'
    foreach ($p in $endpoint.params) {
        $param = $param + "," + "`n" + '        [parameter(mandatory=$True)]$' + $p 
    }

    if ($endpoint.method -match 'post|put') {
        $param = $param + "," + "`n" + '        [parameter(mandatory=$True)]$body'
    }

    $param = @("   Param(", $param , "    )") -join "`n"
    return $param
}

function toTitleCase ($astring) {
        return [string](($astring[0]).tostring()).toupper() + ($astring -replace '^.', '')
}
function new-sumofunctionname {
    Param(
        [parameter(Mandatory = $true)]$endpoint
    )

    $list = $endpoint.uri -split "/"

    $psobject = ''


    foreach ($item in $list ) {
        if ($item -match '^[a-zA-Z]+$') { 
            $add =  "$item"

            # some apis have multiple versions so we don't want to overlap function names.
            if ($add -match 'ingestBudgets') {
                $add = $add -replace 's$',"s$($endpoint.v)"
            }

            if ($endpoint.uri -match '\{[a-z]*id\}' -and $item -match 'ingestBudgets') {
                $add = $add -replace 'sv[0-9]', "$($endpoint.v)"
            }  
            
            # if we have a {param} remove the traling s but only for certain ones that are not valid plural named
            if ($endpoint.uri -match '\{[a-z]*id\}' -and $item -match 'accessKeys|apps|connections|extractionRules|fields|healthEvents|lookupTables|metricsAlertMonitors|monitors|partitions|roles|scheduledViews|tokens|transformationRules|users|dashboards' -and $item -eq ( $endpoint.uri -split "/")[2]) {
                $add = $add -replace 's$', ''
            }     

            # if we are not doing a get, and not the last item it's probably a new-item
            if ($endpoint.method -ne 'get' -and $item -match 'accessKeys|apps|connections|extractionRules|fields|healthEvents|lookupTables|metricsAlertMonitors|monitors|partitions|roles|scheduledViews|tokens|transformationRules|users|dashboards') {
                $add = $add -replace 's$', ''
            }  

            $psobject = $psobject + ( toTitleCase $add)
        }
    }
    

    $psverb = "$($endpoint.method)"
    if ($endpoint.method -match 'post') { $psverb = "New" }
    if ($endpoint.method -match 'put') { $psverb = "Set" }
    if ($endpoint.verb -match 'reset') { $psverb = "Reset"; }
    if ($endpoint.verb -match 'enable|disable') { $psverb = "Set"; }

    if ($endpoint.uri -match '\{[a-z]*id\}') {
        $psobject = $psobject + 'ById'
    }
    
    return (( toTitleCase $psverb) + '-' + $psobject )
}

function new-SumoFunctionBlock {
    Param(
        [parameter(Mandatory = $true)]$endpoint
        
    )

    

    $block = @((new-SumoCommentBlock -endpoint $endpoint),"`n", "function $( new-sumofunctionname -endpoint $endpoint) {`n"  , (new-SumoParamsBlock -endpoint $endpoint), (new-sumoReturnBlock -endpoint $endpoint), '}', '') -join "`n"

    return $block
}
    