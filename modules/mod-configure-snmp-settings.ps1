<#
 ==========================================================================================================================
   Disclaimer
 ==========================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.

 ==========================================================================================================================
 Module:		mod-configure-snmp-settings.ps1
 ==========================================================================================================================
  Author:  Christian Renaud
  Date:    2019/01/23
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by someone
  
 ==========================================================================================================================
 Description:	This Module will configure the SNMP configuration on a given host. The settings must be defined in a CSV
                file and must be valid
 -------------------------------------------------------------------------------------------------------------------------
 Test Environment:	PowerShell 5.1.17134.407
					PowerCli Module 11.0.0.10336080
					Windows 10 Workstation
                    vSphere 6.7

                    Above is my test environment, but this may potentially work with older supported versions
 -------------------------------------------------------------------------------------------------------------------------
 Pre-requisite:	Rights to connect to the target vCenter or vSphere Server
 -------------------------------------------------------------------------------------------------------------------------

 Parameter(s):		One of the following parameter(s) needs to be provided when calling this module

						csv			file definition
                        esx 		vSphere Host to validate SNMP settings against
                        settings    array of settings to apply

 -------------------------------------------------------------------------------------------------------------------------

 Return:			none

 -------------------------------------------------------------------------------------------------------------------------
#>

FUNCTION configure-snmp-settings () {

	#------------------------------------------#
	# Module Input Parameter(s)
	#------------------------------------------#

	PARAM(
		[String]$esx,
        [String]$csv,
        [String[]]$settings
	)

	#------------------------------------------#
	# Variable(s) Initialisation
	#------------------------------------------#

    $snmpdef = Import-Csv $csv                 # Import the Desired Configuration State Stored in a CSV file

	#------------------------------------------#
	# Module Action(s)
	#------------------------------------------#

    # Get esxcli for specified esxi host
    $esxcli = Get-EsxCli -VMHost $esx -V2

    IF ($esxcli) {

        FOREACH ($setting in $settings) {
            # Retrieve the setting value from the SNMP definition
            $snmpvalue = ($snmpdef | where-object setting -eq $setting).value
            Write-Host "Applying $setting on $esx"

            IF ($snmpvalue) {
                $esxcli.system.snmp.set.Invoke(@{$setting = $snmpvalue})
            }
        }
    }
}