# Metricsearches

## Getting a list of metric type objects
We can do this via the content api using itemtype 'Metric'
For example:
```
(get-PersonalFolder ).children |  where {$_.itemtype -match 'Metric'}
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

## get metric search by id
```
Get-MetricsSearchById -id 00000000011EE063       
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
create from example file and save to the personal folder.

```
$mq = Get-Content -Path ./library/metricsearch.json | ConvertFrom-Json -Depth 10
$mq.parentId = (get-PersonalFolder ).id
New-MetricsSearch -body $mq 
```
