
#Import-Module -Name (Get-ChildItem -Filter *psd1 -Recurse ./psm/).FullName
# import-module /psm/Pester

cd /home
Import-Module ./home/sumo-content-powershell/sumologic-content.psd1

# validate env
write-host "SUMO_DEPLOYMENT: '$($env:SUMO_DEPLOYMENT)'"

if (!$Env:SUMO_ACCESS_ID -or !$Env:SUMO_ACCESS_KEY  ) { 
   Write-Warning "Setting SUMO_DEPLOYMENT,SUMO_ACCESS_KEY and SUMO_ACCESS_KEY is recommended to use this container.`n"; 
} 

write-host "Module locally imported with: `nImport-Module ./home/sumo-content-powershell/sumologic-content.psd1`n"
write-host "Start a session with: `n`$sumo_session = New-ContentSession" 
write-host "To see commands:`nget-command -module sumo-content-powershell"
