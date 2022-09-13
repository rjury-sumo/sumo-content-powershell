# sumo-content-powershell
powershell commands for interacting with content ,  folder and other APIs.

For info on apis that exist and swagger definition see: https://api.au.sumologic.com/docs/#section/Getting-Started

 - [collectors.md](docs/collectors.md)
 - [connection_and_sessions.md](docs/connection_and_sessions.md)
 - [content.md](docs/content.md)
 - [dashboardreports.md](docs/dashboardreports.md)
 - [dashboards.md](docs/dashboards.md)
 - [extractionrules.md](docs/extractionrules.md)
 - [fields.md](docs/fields.md)
 - [folders.md](docs/folders.md)
 - [healthevents.md](docs/healthevents.md)
 - [hierarchies.md](docs/hierarchies.md)
 - [ingestbudgets.md](docs/ingestbudgets.md)
 - [logsearchestimatedusage.md](docs/logsearchestimatedusage.md)
 - [lookuptables.md](docs/lookuptables.md)
 - [metricsearch.md](docs/metricsearch.md)
 - [monitors.md](docs/monitors.md)
 - [partitions.md](docs/partitions.md)
 - [permissions.md](docs/permissions.md)
 - [roles.md](docs/roles.md)
 - [searchjob.md](docs/searchjob.md)
 - [setup.md](docs/setup.md)
 - [slos.md](docs/slos.md)
 - [sources.md](docs/sources.md)
 - [users.md](docs/users.md)

# setup
You can import the module as below. The only folder you need is the [sumo-content-powershell](./sumo-content-powershell) folder.

```
Import-Module ./sumo-content-powershell/sumo-content-powershell.psd1
```

# dot sourcing
An alternative is to 'dot source' the module code directly for example: 
```
foreach ($f in dir ./sumo-content-powershell/*.ps1) { if ($f.name -inotmatch 'build') {. $f.fullname}  }
```

# running in docker
You can use the pre-compiled docker image (based on powershell and includes pester)
To run
```
docker run --env SUMO_DEPLOYMENT=au --env SUMO_ACCESS_ID=$SUMO_ACCESS_ID --env SUMO_ACCESS_KEY=$SUMO_ACCESS_KEY -it rickjury/sumo-content-powershell:latest

$sumo_session = new-ContentSession
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
lookuptables (partial)
metricalertmonitors
metricsearch
monitors
partitions
permissions
roles
scheduledviews
searchjob
slos (partial)
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
A pester test file with some rather incomplete test coverage!

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

