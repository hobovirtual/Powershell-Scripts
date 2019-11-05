<#
 =================================================================================================================================================
   Disclaimer
 =================================================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.
 I intend to manage error exception in the best i can, although some exceptions may not be trapped. if you encounter some issue, please let me 
 know.

 =================================================================================================================================================
  Script:	 maint-esxi-update.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/11/04
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will update an ESXi host using Update Manager, although this task is trivial, this script will add some additional
                functionality such
                        - Validate NSX VIB version following update/upgrade
                        - Handle CVM shutdown on Nutnanix Host                        
                        - Validate Nutanix Cluster Status before removing maintenance mode
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:	- PowerShell 5.1.17134.407
                    - Windows 2016 Server
                    - vSphere 6.5/6.7
                    - PRISM X.Y.Z

  Above is my test environment, but this may potentially work with other supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on vCenter Server
                 PRISM and CVM access
                 Update Manager Baseline must exist

 =================================================================================================================================================
#>
# ================================================================================================================================================
# Help Section
# ================================================================================================================================================
#@  Description: 
#@
#@    This Script can be used to perform update/upgrade maintenance on ESXi Host via update manager baseline
#@    
#@  Usage:
#@
#@    maint-esxi-update.ps1 .... [ Common Parameters ]
#@
#@    [ -vc ]       : virtual Center
#@    [ -cl ]       : vSphere Cluster   NOTE: not supported at the moment
#@    [ -esx ]      : vSphere Host(s)   NOTE: Single host supported at the moment
#@    [ -version ]  : Baseline version 
#@    [ -ntnx ]     : Indicate that this is a Nutanix host/cluster 
#@
#@  Common Parameters
#@    [ -Help ]     : Display help
#@
#@  Examples:
#@
#@    maint-esxi-update.ps1 -vc myvc.myorg.org -cl cluster1,cluster2 -version 65U3a
#@    maint-esxi-update.ps1 -esx esx1,esx2 -version 67U2 -ntnx
#@    maint-esxi-update.ps1 -Help
#@    
# ================================================================================================================================================

param ( 
  [string]$vc,                                    # String - vCenter Connection IP|FQDN - Single input - Needs to provide a cluster or host(s)
  [string[]]$cl,                                  # String - vSphere Cluster Name as listed in vCenter - Multiple Input supported comma seperated
  [string[]]$esx,                                 # String - vSphere Host(s) IP|FQDN - Multiple Input supported comma seperated
  [string]$version,                               # String - Indicate the version of the Baseline to use - Need to follow naming convention     
  [switch]$ntnx,                                  # Switch - Check Compliancy against one or more vSphere Host(s)
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = Split-Path $myInvocation.MyCommand.Path        # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = Split-Path $myInvocation.MyCommand.Path -Leaf   # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# Function to Connect to vCenter or vSphere Host
Import-Module -Name "$ScriptDirectory\modules\mod-connect-vsphere-server.ps1" -Force:$true

# Function putting vSphere host in maintenance
Import-Module -Name "$ScriptDirectory\modules\mod-host-enter-maintenance.ps1" -Force:$true

# =================================================================================================================================================
if ($help -or (!$vc -and !$esx)) {
    Show-Usage -ScriptFullPath $ScriptFullPath
    exit
  } 
  
# Parameters Input Validation - if vCenter > Build list of esxi hosts
if ($vc) {
    if ($cl -or $esx) {
        $rc = connect-vsphere-server -vc $vc

        if ($rc -and $cl) {
            # Build List of all vSphere Host(s) in Cluster(s) provided
            $esx = (Get-VMHost -Location $cl).Name
        } else {
            $esx = (Get-VMHost -Name $esx).Name
        }

        # Get Upgrade Baseline 
        $baseline = Get-Baseline -BaselineType Upgrade -TargetType Host -Name $version

        # Get Baseline Build Number
        $build = $baseline.UpgradeRelease.Build

        # Get Target Host Build
        $esxbuild = (Get-VMHost -Name $esx | select build).Build

        # Compare Target vs Installed Build
        if ([int]$esxbuild -le [int]$build) {
            # Enter Maintenance Mode
            if ($ntnx) {
                $isinmaint = host-enter-maintenance -esx $esx -ntnx
            } else {
                $isinmaint = host-enter-maintenance -esx $esx 
            }

            Write-Host "Updating ESXi host to build $build"
            # Attach Baseline if not attached to host
            if (-Not (Get-Baseline -Entity $esx -Name $version)) {
                Attach-Baseline -Entity $esx -Baseline $baseline -Confirm:$false
            }

            # Apply Baseline to ESXi Host
            $rc = Update-Entity -Entity $esx -Baseline $baseline -HostFailureAction Retry -HostNumberOfRetries 2 -HostDisableMediaDevices $true -WhatIf

        } else {
            Write-Host -Background Green -Foreground White "Host build number is matching the baseline provided......Nothing to do!!"
        }
    } else {
        Write-Error "Please set a single or multiple cluster/esxi host when specifying a vCenter Server connection, use -help for additional information"
        exit
    }
}
<#
if ($esx) {

    FOREACH ($esxhost in $esx) {
  
        # Connect to individual esxi host if no vCenter Connection was provided
        if (!$vc) {
            $rc = connect-vsphere-server -esx $esxhost
        }
} else {
    Write-Error "Please validate input and execution, list of esxi host is empty"
}
#>
# Disconnect from vCenter Server
Disconnect-VIServer * -Force:$true -Confirm:$false