<#
 =================================================================================================================================================
   Disclaimer
 =================================================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.

 =================================================================================================================================================
  Script:	 sec-host-snmp-configuration.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/01/09
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by ?
              Comments
 =================================================================================================================================================
  Description: This Script will use esxcli commands to secure and configure SNMP as per best practices and aligned with
               VMware Security Guide for vSphere 6.5+	
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:	- PowerShell 5.1.17134.407
					          - PowerCli Module 11.0.0.10336080
					          - Windows 10 Workstation
                    - vSphere 6.7

  Above is my test environment, but this may potentially work with older supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on target ESXi Host
                 Configuration Setting Definition in CSV format (.\config\somefile.csv)
 =================================================================================================================================================
#>
# ================================================================================================================================================
# Help Section
# ================================================================================================================================================
#@  Description: 
#@    
#@  Usage:
#@
#@    sec-host-snmp-configuration.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@
#@  Mandatory parameter(s):
#@
#@    [ -vc ]       : virtual Center
#@    [ -cl ]       : vSphere Cluster
#@    [ -esx ]      : vSphere Host(s) - Currently not working
#@    [ -check ]    : Validate Configuration based on Standard definition
#@
#@  Common Parameters
#@    [ -Help ]     : Display help
#@
#@  Examples:
#@
#@    sec-host-snmp-configuration.ps1 -vc myvc.myorg.org -cl mycluster -check
#@    sec-host-snmp-configuration.ps1 -Help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

PARAM ( 
  [string]$vc,                                    # String - vCenter Connection IP|FQDN - Single input - Needs to provide a cluster or host(s)
  [string[]]$cl,                                  # String - vSphere Cluster Name as listed in vCenter - Multiple Input supported comma seperated
  [string[]]$esx,                                 # String - vSphere Host(s) IP|FQDN - Multiple Input supported comma seperated       
  [switch]$check,                                 # Switch - Check Compliancy against one or more vSphere Host(s)
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = Split-Path $myInvocation.MyCommand.Path
$ScriptFullPath = Split-Path $myInvocation.MyCommand.Path -Leaf

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# Function to Connect to vCenter or vSphere Host
Import-Module -Name "$ScriptDirectory\modules\mod-connect-vsphere-server.ps1" -Force:$true		

# =================================================================================================================================================
# IF -Help parameter is used - Show Script Usage
IF ($help) {
  Show-Usage -ScriptFullPath $ScriptFullPath
  EXIT
}

# Parameters Input Validation
IF ($vc) {
  IF ($cl -OR $esx) {
    $rc = connect-vsphere-server -vc $vc

    IF ($rc) {
      # Build List of all vSphere Host(s) in Cluster(s) provided
      $esx = Get-VMHost -Location $cl
    }
    
  } ELSE {
    Write-Error "Please set a single or multiple cluster/esxi host when specifying a vCenter Server connection, use -help for additional information"
    EXIT
  }
}