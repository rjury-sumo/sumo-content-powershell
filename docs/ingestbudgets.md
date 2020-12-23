# ingest budgets

There is a v1 and v2 api for the old new budgets features.

# v2 budgets



# v1 budgets
## Get-IngestBudgetsv1
gets all the budgets

## get by id
```
Get-IngestBudgetv1ById -id 00000000000004A5
```

## collectors in a v1 budget
```
get-IngestBudgetv1CollectorsById -id 00000000000004A5
```

returns a list of items with id, and name properties

## create a v1 budget
```
$bv1 = Get-Content -Path ./library/ingestbudgetv1-new.json -Raw| convertfrom-json -Depth 10
```

## assign collector to v1 budget
```
Set-IngestBudgetv1CollectorsById -id 0000000000002A13 -collectorId 109028144
```

## remove collector from v1 budget
```
Remove-IngestBudgetv1CollectorsById -id 0000000000002A13 -collectorId 109028144
```

## reset a v1 budget
```
Reset-IngestBudgetv1UsageResetById -id 0000000000002A13
```

## update a v1 budget
```
$b1 = Get-IngestBudgetv1ById -id 0000000000002A134
$b1.name = "Developer Budget Update via API"
Set-IngestBudgetv1ById -id 0000000000002A13 -body $b1
```

## remove an ingest budget
```
Remove-IngestBudgetv1ById -id $b1.id
```

