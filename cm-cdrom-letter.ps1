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
  Script:	 cm-cdrom-letter.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/08/08
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will remotely change the CD-Rom letter on a given system
                This script will be mainly used on a PowerShell and require WinRM to be configured
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:	- PowerShell 5.1.17134.407
					          - Windows 2016 Server

  Above is my test environment, but this may potentially work with other supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on local powershell host and target server
 =================================================================================================================================================
#>
# ================================================================================================================================================
# Help Section
# ================================================================================================================================================
#@  Description: 
#@
#@    This Script can be used to change the cd-rom letter on a windows server
#@    All interactions are done remotely via winrm
#@    Please make sure that all requirements have been met to sucessfully run this script
#@    
#@  Usage:
#@
#@    cm-cdrom-letter.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -target ]   : target windows server [FQDN|IP]
#@    [ -letter ]   : letter for cd-rom
#@
#@  Common Parameters
#@    [ -help ]     : Display help
#@
#@  Examples:
#@
#@    cm-cdrom-letter.ps1 -target myserver.myorg.org -letter y
#@    cm-cdrom-letter.ps1 -Help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

PARAM ( 
  [string]$target,                                # String - windows server FQDN or IP
  [string]$letter,                                # String - CD-ROM letter
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = Split-Path $myInvocation.MyCommand.Path        # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = Split-Path $myInvocation.MyCommand.Path -Leaf   # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# =================================================================================================================================================
# IF -Help parameter is used - Show Script Usage
IF ($help -OR (!$check -AND !$set)) {
  Show-Usage -ScriptFullPath $ScriptFullPath
  EXIT
} 

# Parameters Input Validation - If vCenter > Build list of esxi hosts
IF ($target -AND $letter) {
  Invoke-Command -ComputerName $target -ScriptBlock {
    $cdrom = Get-WmiObject win32_volume -filter 'DriveType = "5"'
    $cdrom.DriveLetter = $USING:letter+":"
    $cdrom.Put()
  }
} ELSE {
  Write-Error "One or more parameters are missing or incorrect, please validate script input(s)"
}