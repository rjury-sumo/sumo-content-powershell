right now this is not a true module. 

To use is 'dot source' it in a powershell session to create the functions and sumo data type:
```
foreach ($f in dir ./src/*.ps1) { . $f.fullname }

or from root:
. ./dot.source.ps1