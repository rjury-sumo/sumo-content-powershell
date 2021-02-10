# sumo-content-powershell
powershell commands for interacting with content ,  folder and other APIs.

For info on apis that exist and swagger definition see: https://api.au.sumologic.com/docs/#section/Getting-Started

# setup
You can import the module as below. The only folder you need is the sumo-content-powershell folder.

```
Import-Module ./src/sumo-content-powershell.psd1
```

## make a new session
Make a new session using defuatl env vars for endpoint and credentials.
The session is saved as a global variable which subsequent commands will default to sumo_session=$sumo_session
Get a content item by id or path.

```
new-ContentSession -endpoint 'au'
```

or multiple sessions:

```
$test = new-ContentSession -endpoint 'au'
$live = new-ContentSession -endpoint 'us2' -accessid $env:accessidlive -accesskey $env:accesskeylive
```

# Examples of usage
See the docs folder.

# included API 
So far included are followling apis where most endpoints are coded.  Each API has it's own ps.1 code file:
```
accesskeys
apps
collectors
connections
content
dashboards
fieldextrationrules
fields
folders
healthevents
ingestbudgets
logssearchestimatedusage
lookuptables
metricalertmonitors
metricsearch
monitors
partitions
permissions
roles
scheduledviews
searchjob
sources
users
```
# Using the docker image
## custom entry point
By default a pwsh prompt is the entry point. .
Then modify the entrypoint e.g
```
ENTRYPOINT ["pwsh","-File","/home/demo.ps1"]
```

## Build the docker container
to build run
```
docker build -t sumologic-content-powershell:latest .
```

## Starting the container
### windows powershell
```
docker run --env SUMO_DEPLOYMENT=us2 --env SUMO_ACCESS_ID=$Env:SUMO_ACCESS_ID --env SUMO_ACCESS_KEY=$Env:SUMO_
ACCESS_KEY -it sumologic-content-powershell:latest
```

### bash
```
docker run --env SUMO_DEPLOYMENT=au --env SUMO_ACCESS_ID=$SUMO_ACCESS_ID --env SUMO_ACCESS_KEY=$SUMO_ACCESS_KEY -it sumologic-content-powershell:latest
```

# Build notes
# Tests
both code solutions have a pester test file with some rather incomplete test coverage!

# Endpoints
This folder contains files with sumo api endpoints and automation to bulk generate api code. This generated code in ./src is the basis for most of the module code.

# module rebuild
- update *.ps1 code in ./sumo-content-powershell as required
- (ideally)write some pester tests 
- ensure tests pass
- run ./_build.ps1
- update the manifest file such as version setc. Note:  build.ps1 will output the 'exported functions' arrray for the manifest.

# TODO
write more tests!
missing apis such as:
- archive
- transformationrules
- saml
- servicewhitelist
- tokens
- topology (beta)
- account
- passwordpolicy
- dynamicparsing
- serviceallowlist
