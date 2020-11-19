# FER extraction rules

## list
get a list
```
Get-ExtractionRules
```

## get a rule
get just one by id
```
Get-ExtractionRuleById -id 0000000000006118
```

## create or update a rule

use New-ExtractionRule or Set-ExtractionRuleById passing a body payload similar to below example:

```
{
  "name": "ExtractionRule123",
  "scope": "_sourceHost=127.0.0.1",
  "parseExpression": "csv _raw extract 1 as f1",
  "enabled": true
}
```

## delete
```
Remove-ExtractionRuleById -id 00000000000061ED
```