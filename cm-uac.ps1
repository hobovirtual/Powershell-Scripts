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
  Script:	 cm-uac.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/08/08
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will remotely change the CD-Rom letter on a given Windows system
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
#@    This Script can be used to enable or disable UAC on a windows server
#@    All interactions are done remotely via winrm
#@    Please make sure that all requirements have been met to sucessfully run this script
#@    
#@  Usage:
#@
#@    cm-uac.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -target ]   : target windows server [FQDN|IP]
#@    [ -enable ]   : enable UAC
#@    [ -disable ]  : disable UAC
#@
#@  Common Parameters
#@    [ -help ]     : Display help
#@
#@  Examples:
#@
#@    cm-uac.ps1 -target myserver.myorg.org -enable
#@    cm-uac.ps1 -target myserver.myorg.org -disable
#@    cm-uac.ps1 -help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

PARAM ( 
  [string]$target,                                # string - windows server FQDN or IP
  [switch]$enable,                                # switch - enable windows UAC
  [switch]$disable,                               # switch - disable windows UAC
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = "C:\Library"                   # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = "C:\Library\cm-uac.ps1"         # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# =================================================================================================================================================

# if -help parameter is provided or if required parameter(s) are missing(s) - Show Script Usage
IF ($help -OR !$target -AND (!$enable -OR !$disable))  {
  Show-Usage -ScriptFullPath $ScriptFullPath
  EXIT
} 

IF ($disable) {
  $dwordvalue = "0"
} ELSEIF ($enable) {
  $dwordvalue = "1"
}

IF ($target) {
  $creds = Import-CliXml -Path $ScriptDirectory"\Access\service-account.xml"
  Invoke-Command -ComputerName $target -Credential $creds -ScriptBlock {
    New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value $USING:dwordvalue -Force
  }
} ELSE {
  Write-Error "One or more parameters are missing or incorrect, please validate script input(s)"
}