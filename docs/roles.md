# roles

## getting roles
get-roles returns a list of roles. You can request a role by name with:
```
get-roles -name 'Analyst'
```

You can get a role by id if known:
```
Get-RoleById -id 00000000005854F7 
```

## creating roles
use new-role.

for example:
```
$role = Get-Content -Path ./library/role-new.json | convertfrom-json -depth 10
$role.users = @()
$role.name = 'api test role'
$role.description = 'created via the api'
$role.filterPredicate = '_sourcecategory=nothing'
New-Role -body $role -sumo_session $test

```
Note to populate users if not using SAML groups you must use the users api to get their correct ids!

## updating roles
suggested method. get the role first via api, update the required params then post back.

```
role = get-roles -name 'api test role' -sumo_session $test
$role.description = 'updated via api'  
Set-RoleById -id $role.id -body $role -sumo_session $test
```

## assigning users to roles
```
Set-RoleUserById -roleId $role.id -userId 0000000000587F13 -sumo_session $test
```

## remove a role
```
Remove-RoleById -id $role.id
```