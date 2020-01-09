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
  Script:     cm-delete-computer-account.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2020/01/06
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will delete a computer account in active directory if it exist
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:    - PowerShell 5.1.17134.407
                              - Windows 2016 Server

  Above is my test environment, but this may potentially work with other supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on local powershell host and active directory server

                 Modify the following variables
                  scriptdirectory
                  scriptfullpath

 =================================================================================================================================================
#>
# ================================================================================================================================================
# Help Section
# ================================================================================================================================================
#@  Description: 
#@
#@    This Script can be used to delete the computer object in active directory
#@    AD Powershell module installed on the host running the script
#@    Please make sure that all requirements have been met to sucessfully run this script
#@    
#@  Usage:
#@
#@    cm-delete-computer-account.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -name ]     : computer name
#@
#@  Common Parameters
#@    [ -help ]     : Display help
#@
#@  Examples:
#@
#@    cm-delete-computer-account.ps1 -name server001
#@    cm-delete-computer-account.ps1 -help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

param ( 
  [string]$name,                                  # string - dns record name
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$scriptdirectory = "C:\library\powershell"                                  # Script Full Directory Path (running from) ex: C:\temp\
$scriptfullpath = "C:\library\powershell\cm-delete-computer-account.ps1"    # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$scriptdirectory\modules\mod-show-usage.ps1" -Force:$true

# =================================================================================================================================================

# if -help parameter is provided or if required parameter(s) are missing(s) - Show Script Usage
if ($help -OR !$zone -OR !$name -OR !$ip)  {
  Show-Usage -scriptfullpath $scriptfullpath
  exit
}

if (Get-ADComputer -Filter 'Name -eq $name') {
  Write-Host "Computer account for $name found in active directory, proceeding with the removal"
	Remove-ADComputer -Identity $name -Confirm:$false -Force
}