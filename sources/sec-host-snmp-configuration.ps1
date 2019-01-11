#==========================================================================================================================
#   Disclaimer
#==========================================================================================================================
<#
This code is not officially supported and is provided as is.

Although I intend to maintain these as best as i can, the code below may stop working with future release.
I will provide as much information and comments in this code to guide you.
#>
#==========================================================================================================================
# Script:		sec-host-snmp-configuration.ps1
#==========================================================================================================================
<#
  Author:  Christian Renaud
  Date:    2019/01/09
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by ?
              Comments
#>
#==========================================================================================================================
# Description:	This Script will use esxcli commands to secure and configure SNMP as per best practices and aligned with
#               VMware Security Guide for vSphere 6.5+	
# -------------------------------------------------------------------------------------------------------------------------
<#
  Test Environment:	PowerShell 5.1.17134.407
					PowerCli Module 11.0.0.10336080
					Windows 10 Workstation
                    vSphere 6.7

                    Above is my test environment, but this may potentially work with older supported versions
#>
# -------------------------------------------------------------------------------------------------------------------------
# Pre-requisite:	Elevated Rights on target ESXi Host
# -------------------------------------------------------------------------------------------------------------------------
