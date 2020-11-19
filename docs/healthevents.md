# health events.

these are pretty straightforward.

get-healtheventresources is **actuallay a POST.**

```
Get-HealthEventResources -sumo_session $be -body @{'data'=@(@{'id'='00000000234561C1'; 'name'='sumo'; 'type'='Source';})}
```
