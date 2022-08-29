# fields

these are pretty obvious. 
```
get-fields | Sort-Object -Property fieldName
```

# available functions:
Get-Fields
New-Field
Get-FieldsBuiltin
Get-FieldBuiltinById
Get-FieldsDropped
Get-FieldsQuota
Delete-FieldById
Get-FieldById
Set-FieldDisableById
Set-FieldEnableById

# example - create the fields for ec2
An Installed Collector automatically pulls AWS instance identity documents (IMDSv2) from instances to get their accountID, availabilityZone, instanceId, instanceType, and region.

Many customers don't realize these are present but being dropped as need to be created.

We can easily determine  the fields presence, status. and create if necessary.

```
get-fields | where {$_.fieldname -match 'instanceid|region|instancetype|availabilityzone|accountid' } 
```

to create them:

```
foreach ($field in ('instanceid|region|instancetype|availabilityzone|accountid' -split '\|')) {
    new-field -name $field
}
```

