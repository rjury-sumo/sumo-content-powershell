
#Import-Module -Name (Get-ChildItem -Filter *psd1 -Recurse ./psm/).FullName
import-module /psm/Pester

cd /home
Import-Module ./home/sumo-content-powershell/sumo-content-powershell.psd1

# validate env
write-host "SUMO_DEPLOYMENT is: '$($env:SUMO_DEPLOYMENT)'"

if (!$Env:SUMO_ACCESS_ID -or !$Env:SUMO_ACCESS_KEY  ) { 
   Write-Warning "Setting SUMO_DEPLOYMENT,SUMO_ACCESS_KEY and SUMO_ACCESS_KEY is recommended to use this container.`nYou must specify these for New-ContentSession on command line." ; 
   
} 
