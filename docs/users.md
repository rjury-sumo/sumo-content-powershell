# users

## listing users
```
Get-Users [[-sumo_session] <SumoAPISession>] [[-limit] <string>] [[-sortBy] {firstName | lastName | email}] [[-email] <string>] [[-token] <string>] [<CommonParameters>]
```

```
get-users -sortBy lastName
get-users -email 'clark.kent@superman.com'
```

we can get by id also:
```
Get-UserById -id 0000000000587F13
```

## Creating a user

simple example.

Note you can assign a user to a role here or in the roles api also.

```
$user = gc -Path ./library/user-new.json | ConvertFrom-Json -depth 10
$user.roleIds = @((get-roles -name 'Analyst').id)
$user.firstName = 'Jane'
$user.lastName = 'Smith'
$user.email = 'jsmith@nowhere.com'
 ```

 ## updating a user

create an object with the required proprties. If you don't include an id property in the body the post fails despite what the api docs say.

```
$user = get-users -email 'jsmith@nowhere.com' | select-object -Property firstName,lastName,isActive,roleIds,id
$user.firstName = 'James'
Set-UserById -id $user.id -body $user   
```

## removing users
```
Remove-UserById -id $user.id
```

## passwords, email and MFA.
see the API docs for info on these.
```
New-UserEmailRequestChangeById [[-sumo_session] <SumoAPISession>] [-id] <Object> [-body] <Object> [<CommonParameters>]
Reset-UserPasswordById [[-sumo_session] <SumoAPISession>] [-id] <Object> [<CommonParameters>]
Set-UserMfaDisableById [[-sumo_session] <SumoAPISession>] [-id] <Object> [-body] <Object> [<CommonParameters>]
Set-UserUnlockById [[-sumo_session] <SumoAPISession>] [-id] <Object> [<CommonParameters>]

```