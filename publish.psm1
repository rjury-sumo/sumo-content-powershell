Copy-Item -Path ./sumo-content-powershell/*.psm1 ./sumologic-content/ -Force
Copy-Item -Path ./sumo-content-powershell/*.psd1 ./sumologic-content/ -Force
Publish-Module -Path ./sumologic-content -NuGetApiKey $env:PSGALLERY_KEY #-WhatIf -Verbose