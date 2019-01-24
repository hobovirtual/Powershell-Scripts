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
  Description:	This Module will display the help header found inside a given script
 -------------------------------------------------------------------------------------------------------------------------
  Test Environment:	PowerShell 5.1.17134.407
					PowerCli Module 11.0.0.10336080
					Windows 10 Workstation
                    vSphere 6.7

                    Above is my test environment, but this may potentially work with older supported versions
 -------------------------------------------------------------------------------------------------------------------------
 Parameter(s):		Script_FullPath	-- This variable need to contains the script fullpath C:\Script\Test.ps1
 -------------------------------------------------------------------------------------------------------------------------
#>
FUNCTION Show-Usage {

	#------------------------------------------#
	# Module Input Parameter(s)
	#------------------------------------------#

	PARAM (
		[String]$Message = $null,
		[String]$ScriptFullPath
	)
	
	#------------------------------------------#
	# Module Actions
	#------------------------------------------#
	
	[Console]::Error.WriteLine()
	
	# Display specIFic usage error IF one was specIFied
	IF ($Message)
	{
		[Console]::Error.WriteLine($Message)
		[Console]::Error.WriteLine()
	}
	
	# Use usage information from the script header
	Select-String '^#@' -Path "$ScriptFullPath" | 
	Foreach-Object { [Console]::Error.WriteLine($_.Line -replace '^#@','') }
	[Console]::Error.WriteLine()
	
}