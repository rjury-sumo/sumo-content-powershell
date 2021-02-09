# sumo-content-powershell
powershell commands for interacting with content and folder apis

## src
theses are the source files to dot source the functions.
for now it's not a psm just dot source.

## endpoints
this folder contains some files with sumo api endpoints and automation to bulk generate api code.

# setup
right now this is not a true module. 

To use is 'dot source' it in a powershell session to create the functions and sumo data type:
```
foreach ($f in dir ./sumo-content-powershell/*.ps1) { . $f.fullname }

or from root:
. ./dot.source.ps1
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

# Tests
both code solutions have a pester test file with some rather incomplete test coverage!

# TODO
- make it a real module not dot source
- migrate more api commands from the endpoints/src after validating/testing
- write more unit test.
