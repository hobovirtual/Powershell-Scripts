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
 Module:		mod-ntnx-prism-cluster-state.ps1
 ==========================================================================================================================
  Author:  Christian Renaud
  Date:    2019/11/04
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 ==========================================================================================================================
 Description:	This Module will validate the health of the Nutanix Object and will return the state
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

                        prism		IP/FQDN used to connect to PRISM

 -------------------------------------------------------------------------------------------------------------------------

 Return:			
 
 -------------------------------------------------------------------------------------------------------------------------
#>

FUNCTION ntnx-prism-cluster-state () {

	#------------------------------------------#
	# Module Input Parameter(s)
	#------------------------------------------#

	param(
		[string]$prism
	)

    #------------------------------------------#
	# Variable(s) Initialisation
	#------------------------------------------#

    $clusterhealth = $false
    
	#------------------------------------------#
	# Module Action(s)
	#------------------------------------------#

    # Get Nutanix Cluster Status
    $creds = Get-Credential

    if ($creds) {
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $url = "https://$prism:9440/api/nutanix/v2.0/cluster/domain_fault_tolerance_status/"
        $username = $creds.Username
        $password = $creds.GetNetworkCredential().Password
        $header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username+":"+$password ))}
        
        while (-not ($clusterhealth)) {
            $response = Invoke-RestMethod -Method Get -Uri $url -Headers $header
        
            $node = $response | Where-Object { $_.domain_type -eq "NODE" }
            $nodestaticconf = $node.component_fault_tolerance_status.STATIC_CONFIGURATION.number_of_failures_tolerable
            $nodeextent = $node.component_fault_tolerance_status.EXTENT_GROUPS.number_of_failures_tolerable
            $nodezookeeper = $node.component_fault_tolerance_status.ZOOKEEPER.number_of_failures_tolerable
            $nodestargate = $node.component_fault_tolerance_status.STARGATE_HEALTH.number_of_failures_tolerable
            $nodemetadata = $node.component_fault_tolerance_status.METADATA.number_of_failures_tolerable
            $nodeerasure = $node.component_fault_tolerance_status.ERASURE_CODE_STRIP_SIZE.number_of_failures_tolerable
            $nodeoplog = $node.component_fault_tolerance_status.OPLOG.number_of_failures_tolerable
            $nodefreespace = $node.component_fault_tolerance_status.FREE_SPACE.number_of_failures_tolerable
        
            $disk = $response | Where-Object { $_.domain_type -eq "DISK" }
            $diskextent = $disk.component_fault_tolerance_status.EXTENT_GROUPS.number_of_failures_tolerable
            $diskmetadata = $disk.component_fault_tolerance_status.METADATA.number_of_failures_tolerable
            $diskerasure = $disk.component_fault_tolerance_status.ERASURE_CODE_STRIP_SIZE.number_of_failures_tolerable
            $diskoplog = $disk.component_fault_tolerance_status.OPLOG.number_of_failures_tolerable
            $diskfreespace = $disk.component_fault_tolerance_status.FREE_SPACE.number_of_failures_tolerable
        
            if ($nodestaticconf -eq 1 -and $nodeextent -eq 1 -and $nodezookeeper -eq 1 -and $nodestargate -eq 1 -and $nodemetadata -eq 1 -and $nodeerasure -eq 1 -and $nodeoplog -eq 1 -and $nodefreespace -eq 1 -and $diskextent -eq 1 -and $diskmetadata -eq 1 -and $diskerasure -eq 1 -and $diskoplog -eq 1 -and $diskfreespace -eq 1) {
                $clusterhealth = $true
            } else {
                Write-Host -BackgroundColor Yellow -ForegroundColor White "Cluster is not fully initialize"
                Start-Sleep 45
            }
        }
    }
}