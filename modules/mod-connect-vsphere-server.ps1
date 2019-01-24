<#
 ==========================================================================================================================
   Disclaimer
 ==========================================================================================================================

 This code is not officially supported and is provided as is.

 Although I intend to maintain these as best as i can, the code below may stop working with future release.
 I will provide as much information and comments in this code to guide you.

 ==========================================================================================================================
 Module:		mod-connect-vsphere-server.ps1
 ==========================================================================================================================
  Author:  Christian Renaud
  Date:    2012/04/30
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  2019/01/09  by Christian Renaud
              Maintenance Update
              Updated tested version and comments
              Added Public Disclaimer
 ==========================================================================================================================
 Description:	This Module will use the Connect-ViServer cmdlet to connect to a vCenter Server or a vSphere Host.
				Connection Results (Success or Failure) will be returned to the calling method.		
 -------------------------------------------------------------------------------------------------------------------------
 Test Environment:	PowerShell 5.1.17134.407
					PowerCli Module 11.0.0.10336080
					Windows 10 Workstation
                    vSphere 6.7

                    Above is my test environment, but this may potentially work with older supported versions
 -------------------------------------------------------------------------------------------------------------------------
 Pre-requisite:	Rights to connect to the target vCenter or vSphere Server
 -------------------------------------------------------------------------------------------------------------------------

 Parameter(s):		One of the following parameters needs to be provided when calling this module

						vc			for connecting to a vCenter Server
						esx			for connecting to a esx(i) hosts

					Please note that connecting to a vCenter or an esx(i) host is using the same command, these parameter
					have been split for user clarity. 

 -------------------------------------------------------------------------------------------------------------------------

 Return:			$connected 		(boolean)
									Successful 	= 	$true
									Other 		= 	$false
 -------------------------------------------------------------------------------------------------------------------------
#>

FUNCTION connect-vsphere-server () {

	#------------------------------------------#
	# Module Input Parameter(s)
	#------------------------------------------#

	PARAM(
		[String]$esx,
		[String]$vc
	)

	#------------------------------------------#
	# Variable(s) Initialisation
	#------------------------------------------#

	$connected=$False

	# Transform input into unique variable

    IF ($esx -ne "" -and $esx -ne $null) {
		$vspherehost = $esx
	} ELSEIF ($vc -ne "" -and $vc -ne $nul) {
		$vspherehost = $vc
	}

	#------------------------------------------#
	# Module Action(s)
	#------------------------------------------#

	TRY {																				# Validate if Already connected
	    IF (get-vmhost -Server $vspherehost -State connected -erroraction "Stop") {
	        $connected=$True
	    }
	}
	CATCH {																					    #Try to connect
	    TRY {
	        $viserver=Connect-VIserver -Server $vspherehost -errorAction "Stop"
	        $connected=$True
	    }
	    CATCH {
	        $msg="Failed to connect to server $vspherehost" -f $vspherehost
	        Write-Warning $msg
	        Write-Warning $error[0].Exception.Message
	    }
	}
	RETURN $connected
}