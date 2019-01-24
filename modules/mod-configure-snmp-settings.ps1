<#
 ==========================================================================================================================
   Disclaimer
 ==========================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.
 I intend to manage error exception in the best i can, although some exceptions may not be trapped. If you encounter some 
 issue, please let me know.

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
        [String]$setting
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
        # Retrieve the setting value from the SNMP definition
        $snmpvalue = ($snmpdef | where-object setting -eq $setting).value
        Write-Host "Configuring SNMP setting(s) on $esx $tab"

        IF ($setting -ne "users") {
            $rc = $esxcli.system.snmp.set.Invoke(@{$setting = $snmpvalue})
        } ELSE {
            # Generate auth-hash and priv-hash
            $hash = $esxcli.system.snmp.hash.Invoke(@{authhash = "$snmpvalue"; privhash = "$snmpvalue"; rawsecret = "true"})
            $rc = $esxcli.system.snmp.set.Invoke(@{$setting = "username/$($hash.authhash)/$($hash.privhash)/priv"})
        }

        $validationout = New-Object System.Object
        $validationout | Add-Member -type NoteProperty -name "SNMP Setting" -value $setting
        IF ($rc) {
            $validationout | Add-Member -type NoteProperty -Name "Result" -Value "SUCCESS"
        } ELSE {
            $validationout | Add-Member -type NoteProperty -Name "Result" -Value "FAILED"
        }
        $outtable += $validationout
        $lines = ($outtable | Format-Table -AutoSize | Out-String) -replace "`r", "" -split "`n"
        FOREACH ($line in $lines) {
            IF ($line -match "SUCCESS") {
                Write-Host $line -ForegroundColor Green
            } ELSEIF ($line -match "FAILED") {
                Write-Host $line -ForegroundColor Red
            } ELSE {
                Write-Host $line
            }
        }
    }
}