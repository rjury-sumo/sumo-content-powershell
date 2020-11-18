
Import-Module -Name (Get-ChildItem -Filter *psd1 -Recurse ./psm/).FullName

cd /home
# dot source the code
foreach ($f in dir ./src/*.ps1) { . $f.fullname }

# validate env
write-host "SUMOLOGIC_API_ENDPOINT is: '$($env:SUMOLOGIC_API_ENDPOINT)'"

if (!$Env:SUMO_ACCESS_ID -or !$Env:SUMO_ACCESS_KEY  ) { 
   Write-Warning "Setting SUMO_DEPLOYMENT,SUMO_ACCESS_KEY and SUMO_ACCESS_KEY is recommended to use this container.`nYou must specify these for New-ContentSession on command line." ; 
   
} 
