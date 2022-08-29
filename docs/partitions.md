# partitions

this api is pretty strightforward.

get all partitions
get-partitions

get by id:
get-partitionbyid

# creating
use new-Partition. To see the json payload to validate your parition you can add -dryrun $true.

for example:
```
New-Partition -name 'test1' -routingExpression '_sourcecategory=nothing' -dryrun $true -analyticsTier 'frequent' -retentionPeriod 180  -dataForwardingId 'abc'

{
  "name": "test1",
  "routingExpression": "_sourcecategory=nothing",
  "analyticsTier": "frequent",
  "retentionPeriod": 180,
  "dataForwardingId": "abc"
}
```

