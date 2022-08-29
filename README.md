# sumo-content-powershell
powershell commands for interacting with content ,  folder and other APIs.

For info on apis that exist and swagger definition see: https://api.au.sumologic.com/docs/#section/Getting-Started

# setup
You can import the module as below. The only folder you need is the [sumo-content-powershell](./sumo-content-powershell) folder.

```
Import-Module ./sumo-content-powershell/sumo-content-powershell.psd1
```

# dot sourcing current code
Before the module is rebuilt you can 'dot source' the current code. 

For example here we open the 
```
docker build -t sumo-content-powershell:latest .

```

to run

```
docker run --env SUMO_DEPLOYMENT=au --env SUMO_ACCESS_ID=$SUMO_ACCESS_ID --env SUMO_ACCESS_KEY=$SUMO_ACCESS_KEY -it rick-ury/sumo-content-powershell:latest

new-ContentSession
get-PersonalFolder
```

## make a new session
Make a new content session. You can save the output of this command to a variable to maintain multiple sessions.

Default env vars for endpoint and credentials.
- SUMO_ACCESS_ID
- SUMO_ACCESS_KEY
- SUMO_DEPLOYMENT

The session is saved as a global variable which subsequent commands will default to sumo_session=$sumo_session

Get a content item by id or path.

```
new-ContentSession 
```

or multiple sessions:

```
$test = new-ContentSession -endpoint 'au'
$live = new-ContentSession -endpoint 'us2' -accessid $env:accessidlive -accesskey $env:accesskeylive
```

# library
The [library](./library) folder has json files for many common API formats and examples.

# Examples of usage
See the [docs](./docs) folder.

# included APIs
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
heirarchies
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
This is a powershell core container that imports the module and pester for testing.

## custom entry point
By default a pwsh prompt is the entry point after running profile.ps1.

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
## Tests
both code solutions have a pester test file with some rather incomplete test coverage!

## Endpoints
This folder contains files with sumo api endpoints and automation to bulk generate api code. This generated code in ./src is the basis for most of the module code.

## module rebuild
- update *.ps1 code in ./sumo-content-powershell as required
- (ideally)write some pester tests 
- ensure tests pass
- run ./_build.ps1. this will update the psm and psd files.

# TODO
write more tests!
missing apis such as:
- archive
- transformationrules
- saml
- servicewhitelist
- tokens
- topology
- account
- passwordpolicy
- dynamicparsing
- serviceallowlist
