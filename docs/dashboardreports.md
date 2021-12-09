# Exporting a Dashboard Report

more info see: https://api.au.sumologic.com/docs/#operation/generateDashboardReport

exports dashboard to png/pdf format files.

# generate an export job 
Create an asynchronous job to generate a report from a template, poll for completion and export a file

returns an export object with name, id, type,http_status,filepath and content (byte array) properties.
```
Export-DashboardReport -id 'TlVzZzMS2yRowxt3VdZah2uMXTDDKCLUVPvAG4pe5u32ywgDLJ2i3cBPHLbB' exportFormat 'Pdf'
```

                                                            