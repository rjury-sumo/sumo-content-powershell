# Slos API

## get-slosRootFolder
Get the root slos folder.
Returns JSON type SlosLibraryFolderResponse object with id and children array if there are SLO folders or objects.

## get objects by id
Get and SLO or folder by it's id
```
Get-SloById -id '00000000000002CA'
```

## get path of an slo object by id
```
Get-SloPathById -id '00000000000002CA'
```

## get SLO object by path
These are prefixed with /SLO/ such as: 
- /SLO/Demo Logs SLO
- /SLO/Demo/Demo Metric SLO

```
Get-SloByPath -path '/SLO/Demo Logs SLO'
Get-SloByPath -path '/SLO/Demo/Demo Metric SLO'
```

## return the entire slo tree from a root node id
This cmdlet returns the whole root node as an array recursively starting at the id. If no id is supplied it will start at the root.
For each node the path is added as an addional property making this suitable for export as a csv or json to get a complete list of all slos and folders.

see: examples/slotree.ps1

return all slos and folders from the root node recursively.

```
Get-SloTree 
```

return all slos and folders starting from a folder id
```
Get-SloTree -id 00000000000002C9
```
