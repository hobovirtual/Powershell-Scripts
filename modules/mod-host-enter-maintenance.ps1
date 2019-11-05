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
 Module:		mod-host-enter-maintenance.ps1
 ==========================================================================================================================
  Author:  Christian Renaud
  Date:    2019/11/04
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 ==========================================================================================================================
 Description:	This Module will put a given host into maintenance
                For Nutanix host, the CVM will shutdown properly at the end
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

FUNCTION connect-vsphere-server () {

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

    # Put ESXi Host in Maintenance
    Set-VMHost -VMHost $esx -State Maintenance -Confirm:$false -RunAsync

    # Validate Host State - Must be in maintenance mode - exception for Nutanix, last poweredon is the CVM that will be poweredoff as per Nutanix Bible
    while ((Get-VMHost -Name $esx).ConnectionState -ne "Maintenance") {
        Write-Host "Waiting for host to enter maintenance mode"
        Start-Sleep 45

        if ($ntnx) {
            # Validating VM count - Last powered on VM should be the CVM
            if ((Get-VMHost -Name $esx | Get-VM | Where-Object {$_.powerstate -eq 'PoweredOn'}).count -eq 1) {
                if ((Get-VMHost -Name $esx | Get-VM).Name.StartsWith("NTNX")) {
                    $cvm = (Get-VMHost -Name $esx | Get-VM).Name.StartsWith("NTNX")
                    # Shutting down CVM
                    Write-Host "Shutting down CVM $cvm.Name"
                    $sshsession = New-SSHSession -Computername $cvm.Guest.IPAddress[0] -Credential (Get-Credential)
                    $sshstream = New-SSHShellStream -Session $sshsession
                    $sshstream.WriteLine("/usr/local/nutanix/cluster/bin/cvm_shutdown -P now")
                    while ($cvm.powerstate -ne 'PoweredOff') {
                        Write-Host "Waiting for CVM shutdown"
                        Start-Sleep 30
                    }
                } 
            }
        }
    }
}