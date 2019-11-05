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
 Module:		mod-host-exit-maintenance.ps1
 ==========================================================================================================================
  Author:  Christian Renaud
  Date:    2019/11/04
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 ==========================================================================================================================
 Description:	This Module will remove a given host from maintenance
                For Nutanix host, the CVM will be started
 -------------------------------------------------------------------------------------------------------------------------
 Test Environment:	PowerShell XYZ
					PowerCli Module XYZ
                    vSphere 6.5/6.7

                    Above is my test environment, but this may potentially work with older supported versions
 -------------------------------------------------------------------------------------------------------------------------
 Pre-requisite:	Appropriate rights in vCenter Server
                SSHSession Powershell module must be installed
                For nutanix host, user will need to provide credential of the CVM
 -------------------------------------------------------------------------------------------------------------------------

 Parameter(s):		One of the following parameters needs to be provided when calling this module

                        esx			for connecting to a esx(i) hosts
                        ntnx        indicates if this is nutanix host when present

 -------------------------------------------------------------------------------------------------------------------------

 Return:			
 
 -------------------------------------------------------------------------------------------------------------------------
#>

FUNCTION host-exit-maintenance () {

	#------------------------------------------#
	# Module Input Parameter(s)
	#------------------------------------------#

	param(
		[string]$esx,
		[switch]$ntnx
	)

	#------------------------------------------#
	# Module Action(s)
	#------------------------------------------#

    # Remove ESXi Host from Maintenance
    Set-VMHost -VMHost $esx -State Connected -Confirm:$false

    # Validate Host State - Must be in maintenance mode - exception for Nutanix, last poweredon is the CVM that will be poweredoff as per Nutanix Bible
    if ($ntnx) {
        if ((Get-VMHost -Name $esx).ConnectionState -eq "Connected") {
            $cvm = (Get-VMHost -Name $esx | Get-VM).Name.StartsWith("NTNX")
            if ($cvm) {
                # Power On CVM
                Start-VM -VM $cvm -Confirm:$false
            }
        }
    }
}