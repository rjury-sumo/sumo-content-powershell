# code to bulk create sumo api powershell code

## endpoint txt lists
The txt lists brought to you by: https://github.com/wks-sumo-logic/sumologic-swaggertools

## api-gen.ps1
script to read endpoints.txt and create powershell code files in ./src
This should do most of the grunt work for creating module code.
Likely some methods might need fine tuning or custom code.

### invoke-sumo
This code assumes you already have the ../src/_core.ps1 functions loaded to be workable.

## srcgen.ps1
This creates the ./src files
we can use these to quickly build powershell code for sumo apis.


