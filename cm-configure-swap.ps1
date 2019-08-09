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
  Script:	 cm-configure-swap.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/08/08
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will remotely configure windows SWAP on a given Windows system
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:	- PowerShell 5.1.17134.407
					          - Windows 2016 Server

  Above is my test environment, but this may potentially work with other supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on local powershell host and target server

                 Encrypted / exported credential object available for the user running the command on the powershell host, you can find more 
                 information on how to create this here: 
                 https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-clixml?view=powershell-6

                 Modify the following variables
                  ScriptDirectory
                  ScriptFullPath
                  If the password is located somewhere else than the default ScriptDirectory\Access
 =================================================================================================================================================
#>
# ================================================================================================================================================
# Help Section
# ================================================================================================================================================
#@  Description: 
#@
#@    This Script can be used to configure partition on a windows server
#@    All interactions are done remotely via winrm
#@    Please make sure that all requirements have been met to sucessfully run this script
#@    
#@  Usage:
#@
#@    cm-configure-swap.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -target ]     : target windows server [FQDN|IP]
#@    [ -multiplier ] : multiplier to use X * configured RAM
#@    [ -letter ]     : drive letter where the swap will be configured
#@
#@  Common Parameters
#@    [ -help ]     : Display help
#@
#@  Examples:
#@
#@    cm-configure-swap.ps1 -target myserver.myorg.org -multiplier 1.5 -letter Y
#@    cm-configure-swap.ps1 -help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

param ( 
  [string]$target,                                # string - windows server FQDN or IP
  [int]$multiplier,                               # int - disk number on windows system
  [string]$letter,                                # string - drive letter
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = "C:\Library"                         # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = "C:\Library\cm-configure-swap.ps1"    # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# =================================================================================================================================================

# if -help parameter is provided or if required parameter(s) are missing(s) - Show Script Usage
if ($help -OR !$target -OR !$multiplier -OR !$letter)  {
  Show-Usage -ScriptFullPath $ScriptFullPath
  exit
} 

$creds = Import-CliXml -Path $ScriptDirectory"\Access\service-account.xml"
Invoke-Command -ComputerName $target -Credential $creds -ScriptBlock {
  $physicalmeminfo = Get-WmiObject -class "win32_physicalmemory" -namespace "root\CIMV2"
  Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{Name = $USING:letter":\pagefile.sys"; InitialSize = $physicalmeminfo.Capacity/1Mb*$USING:multiplier; MaximumSize = $physicalmeminfo.Capacity/1Mb*1.5; }
}