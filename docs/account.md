# Account

These endpoints are for account status and billing information. Many use cases only apply to multi account orgs or partners where are parent org owns a number of child orgs under a single contract.

## Get-AccountStatus
Get information related to the account's plan, pricing model, expiration and payment status.

```
Get-AccountStatus -sumo_session $test
```

```
pricingModel       : credits
canUpdatePlan      : False
planType           : Paid
planExpirationDays : 265
applicationUse     : 
accountActivated   : True
totalCredits       : 21900
```


## Get-AccountSubdomin
Get the configured subdomain.

```
createdAt  : 12/6/2020 9:58:16PM
createdBy  : 000000000057B6D2
modifiedAt : 12/6/2020 9:58:16PM
modifiedBy : 000000000057B6D2
subdomain  : some_domain
url        : https://some_domain.au.sumologic.com
```

## Get-AccountUsageForecast
Get usage forecast with respect to last number of days specified. If nothing is provided for last number of days, the average of term period will be taken to do the forecast.

```
Get-AccountUsageForecast -sumo_session $test -numberOfDays 7
```

```
averageUsage              : 0.00738088932439153
usagePercentage           : 0.539351173301902
forecastedUsage           : 120.07384262408
forecastedUsagePercentage : 0.548282386411326
remainingDays             : 265
```

## create a usage report and download from url

## Start-AccountUsageReport
https://api.au.sumologic.com/docs/#operation/exportUsageReport
Export the credit usage details as csv for the specific period of time given as input in the form of a start and end date with a specific grouping according to day, week, month, Note that this API will work only for credits plan customers.

example params:
"startDate": "2019-07-20T00:00:00.000Z"
"endDate": "2019-08-20T00:00:00.000Z"
"groupBy": "day"
"reportType": "standard"
"includeDeploymentCharge": false

```
start-AccountUsageReport -sumo_session $test
```

This will return a single job id value as a string for example:
-2107214432225550922 

## Get-AccountUsageReportJobStatus
Retrieve job result, if the job is complete status will be 'Success' and reportDownloadURL will contain the download link.


```
(Get-AccountUsageReportJobStatus -jobId -2107214432225550922 -sumo_session $test).reportDownloadURL
```

```
Code              : 
message           : 
detail            : 
meta              : 
status            : Success
statusMessage     : 
reportDownloadURL : https://syd-bill-usage-...
```