<#
 =================================================================================================================================================
   Disclaimer
 =================================================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.
 I intend to manage error exception in the best i can, although some exceptions may not be trapped. If you encounter some issue, please let me 
 know.

 =================================================================================================================================================
  Script:	 sec-host-snmp-configuration.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/01/09
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  2019/01/24  by Christian Renaud
              Initial Release after series of QA performed
 =================================================================================================================================================
  Description: This Script will use esxcli commands to secure and configure SNMP as per best practices and aligned with
               VMware Security Guide for vSphere 6.5+	
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:	- PowerShell 5.1.17134.407
					          - PowerCli Module 11.0.0.10336080
					          - Windows 10 Workstation
                    - vSphere 6.7

  Above is my test environment, but this may potentially work with older supported versions
  
  Only the following settings have been tested
                    - authentication
                    - privacy
                    - hwsrc
                    - enable
                    - users
                        + if you need different passphrase per host, you would need to modify the conf file and run it against individual host
                          It is possible to modify the code to change configuration file in a loop, the intention was to provide a definition 
                          per cluster

  Although the other SNMP settings should work, only the above were tested sucessfully. 
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
#@    This Script can be used to validated and/or configure SNMP settings on vSphere Host(s)
#@    All interaction is done via esxcli commands
#@    Please make sure to grab all required module(s) and configuration file(s) before executing the script
#@    SNMP desired configuration(s) are defined in a CSV format in the /conf/snmp-config.csv file
#@    
#@  Usage:
#@
#@    sec-host-snmp-configuration.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -vc ]       : virtual Center
#@    [ -cl ]       : vSphere Cluster
#@    [ -esx ]      : vSphere Host(s)
#@    [ -check ]    : Validate Configuration based on Standard definition
#@
#@  Common Parameters
#@    [ -Help ]     : Display help
#@
#@  Examples:
#@
#@    sec-host-snmp-configuration.ps1 -vc myvc.myorg.org -cl cluster1,cluster2 -check
#@    sec-host-snmp-configuration.ps1 -vc myvc.myorg.org -cl cluster1,cluster2 -set
#@    sec-host-snmp-configuration.ps1 -esx esx1,esx2 -check
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
  [switch]$set,                                   # Switch - Set SNMP configuration against one or more vSphere Host(s)
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = Split-Path $myInvocation.MyCommand.Path        # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = Split-Path $myInvocation.MyCommand.Path -Leaf   # Script Full Path with name ex: C:\temp\myscript.ps1
$csv = "$ScriptDirectory/conf/snmp-config.csv"                    # CSV file with SNMP desired settings definition

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# Function to Connect to vCenter or vSphere Host
Import-Module -Name "$ScriptDirectory\modules\mod-connect-vsphere-server.ps1" -Force:$true

# Function Validating SNMP setting(s) against a vSphere Host
Import-Module -Name "$ScriptDirectory\modules\mod-validate-snmp-settings.ps1" -Force:$true

# Function Configuring SNMP setting(s) against a vSphere Host
Import-Module -Name "$ScriptDirectory\modules\mod-configure-snmp-settings.ps1" -Force:$true

# =================================================================================================================================================
# IF -Help parameter is used - Show Script Usage
IF ($help -OR (!$check -AND !$set)) {
  Show-Usage -ScriptFullPath $ScriptFullPath
  EXIT
} 

# Parameters Input Validation - If vCenter > Build list of esxi hosts
IF ($vc) {
  IF ($cl -OR $esx) {
    $rc = connect-vsphere-server -vc $vc

    IF ($rc) {
      # Build List of all vSphere Host(s) in Cluster(s) provided
      $esx = (Get-VMHost -Location $cl).Name
    }

  } ELSE {
    Write-Error "Please set a single or multiple cluster/esxi host when specifying a vCenter Server connection, use -help for additional information"
    EXIT
  }
}

IF ($esx) {

  FOREACH ($esxhost in $esx) {
    # Initialize empty array
    $nonecompliantsettings = @()

    # Connect to individual esxi host If no vCenter Connection was provided
    IF (!$vc) {
      $rc = connect-vsphere-server -esx $esxhost
    }

    # Following module will check and report the SNMP configuration vs desired state - If check switch is defined, the result will be displayed
    $nonecompliantsettings = validate-snmp-settings -esx $esxhost -csv $csv

    IF ($nonecompliantsettings -and $set) {
      FOREACH ($setting in $nonecompliantsettings) {
        configure-snmp-settings  -esx $esxhost -csv $csv -setting $setting
      }
    }
  }
} ELSE {
  Write-Error "Please validate input and execution, list of esxi host is empty"
}

# Disconnect from vCenter Server
Disconnect-VIServer * -Force:$true -Confirm:$false