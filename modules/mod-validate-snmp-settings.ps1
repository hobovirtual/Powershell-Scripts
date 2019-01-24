<#
 ==========================================================================================================================
   Disclaimer
 ==========================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.

 ==========================================================================================================================
 Module:		mod-validate-snmp-settings.ps1
 ==========================================================================================================================
  Author:  Christian Renaud
  Date:    2019/01/23
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by someone
  
 ==========================================================================================================================
 Description:	This Module will validate the SNMP configuration on a given host. The settings must be defined in a CSV
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

 -------------------------------------------------------------------------------------------------------------------------

 Return:			$notcompliant 	array of value not compliant as per setting(s)

 -------------------------------------------------------------------------------------------------------------------------
#>

FUNCTION validate-snmp-settings () {

	#------------------------------------------#
	# Module Input Parameter(s)
	#------------------------------------------#

	PARAM(
		[String]$esx,
        [String]$csv
	)

	#------------------------------------------#
	# Variable(s) Initialisation
	#------------------------------------------#

    $notcompliant = @()                        # Initialize an empty array to storage none compliant setting(s)
    $snmpdef = Import-Csv $csv                 # Import the Desired Configuration State Stored in a CSV file
    $outtable = @()

	#------------------------------------------#
	# Module Action(s)
	#------------------------------------------#

    # Get esxcli for specified esxi host
    $esxcli = Get-EsxCli -VMHost $esx -V2

    IF ($esxcli) {
        # Retrieve current SNMP configuration
        $snmpconf = $esxcli.system.snmp.get.Invoke()

        IF ($check) {
            Write-Host "Validating SNMP configuration on $esx"
        }

        # Following Check section will only report on SNMP configuration vs desired state
        FOR ($i=0;$i -lt $snmpdef.count;$i++) {
            $snmpsetting = $snmpdef[$i].setting         # Get SNMP setting defined in CSV file
            $snmpvalue = $snmpdef[$i].value             # Get SNMP setting value defined in CSV file
            
            IF ($snmpvalue) {
                IF ($snmpconf.$snmpsetting -eq $snmpvalue) {
                    $result = "PASS"
                } ELSE {
                    $result = "FAIL"
                    $notcompliant += $snmpsetting
                }
            } ELSE {
                IF ($snmpconf.$snmpsetting -ne $null) {
                    $result = "PASS"
                } ELSE {
                    $result = "FAIL"
                    $notcompliant += $snmpsetting
                }
            }
            IF ($check) {
                $validationout = New-Object System.Object
                $validationout | Add-Member -type NoteProperty -name "SNMP Setting" -value $snmpsetting
                $validationout | Add-Member -type NoteProperty -Name "Validation Result" -Value $result
                $outtable += $validationout
            }
        }
    }
    IF ($check) {
        $lines = ($outtable | Format-Table -AutoSize | Out-String) -replace "`r", "" -split "`n"
        FOREACH ($line in $lines) {
            IF ($line -match "PASS") {
                Write-Host $line -ForegroundColor Green
            } ELSEIF ($line -match "FAIL") {
                Write-Host $line -ForegroundColor Red
            } ELSE {
                Write-Host $line
            }
        }
    }
	RETURN $notcompliant
}