#
# Module manifest for module 'sumo-content-powershell'
#
# Generated by: Rick Jury
#
# Generated on: 2/10/2021
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'sumo-content-powershell.psm1'

# Version number of this module.
ModuleVersion = '1.0.11'
#
# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'c1d4dbdb-a978-4987-a8a9-f9652d34f92a'

# Author of this module
Author = 'Rick Jury'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) Rick Jury. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Provides functions for interacting with SumoLogic APIs.'

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('new-ContentSession','getQueryString','invoke-sumo','copy-proppy','convertSumoDecimalContentIdToHexId','New-MultipartBoundary','New-MultipartContent','getArrayIndex ','batchReplace','Get-AccessKeys','New-AccessKey','Get-AccessKeysPersonal','Remove-AccessKeyById','Set-AccessKeyById','Get-Apps','Get-AppInstallStatusById','Get-AppById','New-AppInstallById','Install-SumoApp','get-collectors','get-offlineCollectors','get-collectorById','get-collectorByName','Get-Connections','New-Connection','New-ConnectionTest','Remove-ConnectionById','Get-ConnectionById','Set-ConnectionById','get-ContentByPath','get-ContentPath','start-ContentExportJob','get-ContentExportJobStatus','get-ContentExportJobResult','get-ExportContent','start-ContentCopyJob','get-ContentCopyJobStatus','start-ContentImportJob','Get-ContentFoldersImportStatusById','Move-ContentById','Get-ContentFolderById','Set-ContentFoldersById','Get-Dashboards','New-Dashboard','Remove-DashboardById','Get-DashboardById','Set-DashboardById','Get-DashboardContentIdById','Edit-DashboardPanelQueries','New-DashboardReportJob','Get-DashboardReportJobsResultById','Get-DashboardReportJobsStatusById','Export-DashboardReport','Get-ExtractionRules','New-ExtractionRule','Remove-ExtractionRuleById','Get-ExtractionRuleById','Set-ExtractionRuleById','Get-Fields','New-Field','Get-FieldsBuiltin','Get-FieldBuiltinById','Get-FieldsDropped','Get-FieldsQuota','Replace-FieldById','Get-FieldById','Set-FieldDisableById','Set-FieldEnableById','get-Folder','get-PersonalFolder','get-GlobalFolder','get-adminRecommended','get-folderJobStatus','get-folderJobResult','get-folderContent','new-folder','Get-HealthEvents','Get-HealthEventResources','Get-hierarchies','New-hierarchy','Delete-hierarchyById','Get-hierarchyById','Get-IngestBudgetsv1','New-IngestBudgetsv1','Remove-IngestBudgetv1ById','Get-IngestBudgetv1ById','Set-IngestBudgetv1ById','Get-IngestBudgetv1CollectorsById','Remove-IngestBudgetv1CollectorsById','Set-IngestBudgetv1CollectorsById','Reset-IngestBudgetv1UsageResetById','Get-IngestBudgetsv2','New-IngestBudgetsv2','Remove-IngestBudgetv2ById','Get-IngestBudgetv2ById','Set-IngestBudgetv2ById','Reset-IngestBudgetv2UsageResetById','Get-LogSearchesEstimatedUsage','New-LookupTable','Get-LookupTableJobsStatusById','Remove-LookupTableById','Get-LookupTableById','Set-LookupTableById','Remove-LookupTableRowById','New-LookupTableRowById','New-LookupTableTruncateById','Set-LookupTableFromCsv','Get-MetricsAlertMonitors','New-MetricsAlertMonitor','Remove-MetricsAlertMonitorById','Get-MetricsAlertMonitorById','Set-MetricsAlertMonitorById','New-MetricsAlertMonitorMuteById','New-MetricsAlertMonitorUnmuteById','New-MetricsSearch','Remove-MetricsSearchById','Get-MetricsSearchById','Set-MetricsSearchById','Get-MonitorsBulkByIds','Get-MonitorsObjectByPath','Get-MonitorsRoot','Get-MonitorsSearch','Get-MonitorsUsageInfo','Remove-MonitorById','Get-MonitorsObjectById','Set-MonitorById','Copy-MonitorById','Get-MonitorExportById','Move-MonitorById','Get-MonitorsObjectPathById','New-MonitorImportById','Get-Partitions','New-Partition','Get-PartitionById','Set-PartitionById','New-PartitionCancelRetentionUpdateById','Set-PartitionDecommissionById','Get-ContentPermissionsById','Set-ContentPermissionsAddById','Set-ContentPermissionsRemoveById','Get-Roles','New-Role','Remove-RoleById','Get-RoleById','Set-RoleById','Remove-RoleUserById','Set-RoleUserById','get-scheduledViews','get-epochDate ','get-DateStringFromEpoch ','get-timeslices ','sumotime','sumolast','epocvalidation ','New-SearchQuery','New-SearchJob','get-SearchJobStatus','Export-SearchJobEvents','get-SearchJobResult','New-SearchBatchJob','Get-SlosRootFolder','Get-SloById','Get-SloPathById','Get-SloByPath','Get-SloTree','get-sources','get-sourceById','Get-Users','New-User','Remove-UserById','Get-UserById','Set-UserById','New-UserEmailRequestChangeById','Set-UserMfaDisableById','Reset-UserPasswordById','Set-UserUnlockById' )
# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("sumologic")

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rjury-sumo/sumo-content-powershell'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/rjury-sumo/sumo-content-powershell'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}










