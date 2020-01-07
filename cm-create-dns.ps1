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
  Script:	 cm-create-dns.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2020/01/06
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  YYYY/MM/DD  by [SOMEONE]
              [DESCRIPTION]
 =================================================================================================================================================
  Description:  This script will create a forward and it's associated pointer dns record in a given dns zone
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:	- PowerShell 5.1.17134.407
					          - Windows 2016 Server

  Above is my test environment, but this may potentially work with other supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on local powershell host and dns server

                 Modify the following variables
                  ScriptDirectory
                  ScriptFullPath

 =================================================================================================================================================
#>
# ================================================================================================================================================
# Help Section
# ================================================================================================================================================
#@  Description: 
#@
#@    This Script can be used to create the forward and reverse dns record on a given dns zone
#@    All interactions are done remotely via winrm
#@    DNS Powershell module installed on the host running the script
#@    Please make sure that all requirements have been met to sucessfully run this script
#@    
#@  Usage:
#@
#@    cm-create-dns.ps1 .... [ Common Parameters ]
#@
#@  Paramaters:
#@
#@    [ -zone ]     : DNS zone name
#@    [ -name ]     : DNS name
#@    [ -ip ]       : IP
#@
#@  Common Parameters
#@    [ -help ]     : Display help
#@
#@  Examples:
#@
#@    cm-create-dns.ps1 -zone zone.local -name server001 -ip 192.168.1.100
#@    cm-create-dns.ps1 -help
#@    
# ================================================================================================================================================

# ----------------------------------------------- #
# Parameters Definition
# ----------------------------------------------- #

param ( 
  [string]$zone,                                  # string - dns zone name
  [string]$name,                                  # string - dns record name
  [string]$ip,                                    # string - dns record ip
  [switch]$help                                   # Switch - Display Help with Comment Prefix #@ 
)

# ----------------------------------------------- #
# Local Variables Definition
# ----------------------------------------------- #

$ScriptDirectory = "C:\Library"                      # Script Full Directory Path (running from) ex: C:\temp\
$ScriptFullPath = "C:\Library\cm-create-dns.ps1"    # Script Full Path with name ex: C:\temp\myscript.ps1

# ----------------------------------------------- #
# Modules Import
# ----------------------------------------------- #

# Function Showing Help for this script
Import-Module -Name "$ScriptDirectory\modules\mod-show-usage.ps1" -Force:$true

# =================================================================================================================================================

# if -help parameter is provided or if required parameter(s) are missing(s) - Show Script Usage
if ($help -OR !$zone -OR !$name -OR !$ip)  {
  Show-Usage -ScriptFullPath $ScriptFullPath
  exit
}

$dnsservers = @("nameorip","nameorip")
$reversefound = $false
$forwardrecord = $false

# test dns server connectivity
foreach ($dnsserver in $dnsservers) {
  $testnet = Test-NetConnection $dnsserver -Port 53

  if ($testnet.TcpTestSucceeded) {
    $dnssvr = $dnsserver
    exit
  }
}

if ($dnssvr) {
  $dnszone = (Get-DnsServerZone -Name $zone -Computername $dnssvr).ZoneName
  # validate reverse dns record
  if (Resolve-DnsName $ip -Server $dnssvr -ErrorAction silentlycontinue) {
    $reversefound = $true
    $output += "reverse dns record for ip $ip found, please validate if this record is still valid or not. as per corporate policy, this situation is acceptable and should not fail a deployment"
  }

  # validate forward dns record
  if ((Resolve-DnsName "$name.$zone" -ErrorAction silentlycontinue)) {
    $forwardrecord = $true
    $output += "forward dns record for $name found, please validate if this record is still valid or not. deployment will fail due to this error to avoid ip conflict"
  }

  # create dns record
  if ($reversefound -eq $false -and $forwardrecord -eq $false) {
    Write-Host "no previous/stale dns record found, creating dns record as requested"
    Add-DnsServerResourceRecordA $dnszone -Name $name -IPv4Address $ip -CreatePtr -ComputerName $dnsserver 
  
  } elseif ($reversefound -eq $true -and $forwardrecord -eq $false) {
    Write-Host "a reverse dns record was found, running validation on this record"

    # validate if the current reverse record match the requested forward record
    if ((Resolve-DnsName $ip -Server $dnssvr).NameHost.Split(".")[0] -ieq $name) {
      Write-Host "the reverse dns record found match the requested forward record, proceeding with the creation of the forward record"
      Add-DnsServerResourceRecordA $dnszone -Name $name -IPv4Address $ip -ComputerName $dnssvr

    } else {
      Write-Host "reverse dns record for ip $ip found, please validate if this record is still valid or not. as per corporate policy, this situation is acceptable and should not fail a deployment"
      exit 2
    }

  } elseif ($reversefound -eq $false -and $forwardrecord -eq $true) {
    Write-Host "a forward dns record was found, running validation on this record"

    if ((Resolve-DnsName "$name.$zone").IPAddress -eq $ip) {
      Write-Host "the forward dns record found match the requested reverse record, proceeding with the creation of the reverse record"
      
      # create ptr record
      $ptr = $ip.split(".")[3]
      $ptr += "."
      $ptr += $ip.split(".")[2]
      $ptrdomain = $name
      $ptrdomain += "."
      $ptrdomain += $DNSZone
      $reversezone = ((Get-DnsServerZone -Computername wspicdnscc01.res.bngf.local) | where {$_.ZoneName -eq "61.10.in-addr.arpa"}).ZoneName
      Add-DnsServerResourceRecordPtr -Name $ptr -ZoneName $reversezone -PtrDomainName $ptrdomain -ComputerName wspicdnscc01.res.bngf.local
    }

  }

} else {
  Write-Error "No DNS server(s) was/were available at the time this script ran, please validate DNS server connectivity and/or availability"
}