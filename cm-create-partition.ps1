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
  Script:	 cm-create-partition.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2019/08/08
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will remotely configure windows partition on a given Windows system
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
#@    cm-create-partition.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -target ]     : target windows server [FQDN|IP]
#@    [ -disknumber ] : Physical Disk Number
#@    [ -letter ]     : Partition Desired Letter
#@    [ -unitsize ]   : OPTIONAL - Partition Allocation Size (bytes)
#@    [ -label ]      : OPTIONAL - Partition Label
#@
#@  Common Parameters
#@    [ -help ]     : Display help
#@
#@  Examples:
#@
#@    cm-create-partition.ps1 -target myserver.myorg.org -disknumber 1 -letter D -label "Drive D" -unitsize 65536
#@    cm-create-partition.ps1 -target myserver.myorg.org -disknumber 1 -letter E
#@    cm-create-partition.ps1 -help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

param ( 
  [string]$target,                                # string - windows server FQDN or IP
  [int]$disknumber,                               # int - disk number on windows system
  [string]$letter,                                # string - drive letter
  [int]$unitsize,                                 # int - allocation unit (bytes)
  [string]$label,                                 # string - partition label
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = "C:\Library"                           # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = "C:\Library\cm-create-partition.ps1"    # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# =================================================================================================================================================

# if -help parameter is provided or if required parameter(s) are missing(s) - Show Script Usage
if ($help -OR !$target -OR !$disknumber -OR !$letter)  {
  Show-Usage -ScriptFullPath $ScriptFullPath
  exit
} 

$creds = Import-CliXml -Path $ScriptDirectory"\Access\service-account.xml"
Invoke-Command -ComputerName $target -Credential $creds -ScriptBlock {
  # Initialize Disk
  if (Get-Disk -Number $USING:disknumber | Where-Object PartitionStyle –Eq 'RAW') {
    Get-Disk -Number $USING:disknumber | Initialize-Disk
  }
  # Create Partition
  if (-not ((Get-Disk -Number $USING:disknumber | Get-Partition).DriveLetter)) {
    if ($USING:unitsize) {
      Get-Disk -Number $USING:disknumber | New-Partition -UseMaximumSize -DriveLetter $USING:letter | Format-Volume -FileSystem NTFS -AllocationUnitSize $USING:unitsize -NewFileSystemLabel $USING:label -Confirm:$False
    } else {
      Get-Disk -Number $USING:disknumber | New-Partition -UseMaximumSize -DriveLetter $USING:letter | Format-Volume -FileSystem NTFS -NewFileSystemLabel $USING:label -Confirm:$False
    }
  } else {
    Write-Error "Disk already contains a partition, please validate"
  }
}