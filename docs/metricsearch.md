# Metricsearches

## only works with API created objects which is super wieird
There is one odd thing about this API that you can only seem to get things you created with it - even though in the UI exisitng and API created metric search objects appear the same in the libaray!

For example:
```
(get-PersonalFolder -sumo_session $training).children |  where {$_.itemtype -match 'Metric'}
createdAt   : 11/22/2020 11:23:18 PM
createdBy   : 0000000000BC774E
modifiedAt  : 11/22/2020 11:23:18 PM       
modifiedBy  : 0000000000BC774E
id      : 00000000011EB967
name    : Metrics Example
itemType    : MetricsV2
parentId    : 0000000000EDB78E
permissions : {GrantEdit, View, Edit, GrantView…}

createdAt   : 11/22/2020 11:30:47 PM
createdBy   : 0000000000BC774E
modifiedAt  : 11/22/2020 11:30:47 PM
modifiedBy  : 0000000000BC774E
id      : 00000000011EE063
name    : Short title
itemType    : Metrics
parentId    : 0000000000EDB78E
permissions : {GrantEdit, View, Edit, GrantView…}
```

requesting the manually saved library search fails:
```
Invoke-WebRequest: /Users/rjury/Documents/sumo2020/sumo-content-powershell/src/_core.ps1:201:19
Line |
 201 |  …       $r = (Invoke-WebRequest -Uri $uri -method $method -WebSession $ …
     |    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | {"id":"DHVFP-HQLYF-19BHI","errors":[{"code":"content:content_not_found","message":"Content with the given ID does not exist."}]}

```

requesting one created via the API works:
```
Get-MetricsSearchById -id 00000000011EE063 -sumo_session $training      
logQuery      : my_metric | timeslice 1m | count by _timeslice
title                     : Short title
description               : Long and detailed description 
metricsQueries    : {@{rowId=A; query=my_metric | avg}}
desiredQuantizationInSecs : 60
properties    : { \"key\": \"value\" }
createdAt     : 11/22/2020 11:30:47 PM
createdBy     : 0000000000BC774E
modifiedAt    : 11/22/2020 11:30:47 PM
modifiedBy    : 0000000000BC774E
id    : 00000000011EE063
parentId      : 0000000000EDB78E
```

# Example create metricsearch

```
$mq = Get-Content -Path ./library/metricsearch.json | ConvertFrom-Json -Depth 10
$mq.parentId = (get-PersonalFolder -sumo_session $training).id
New-MetricsSearch -body $mq -sumo_session $training
```
