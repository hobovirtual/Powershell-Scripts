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
  Script:     cm-delete-dns.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2020/01/06
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  2020/01/28  by Christian Renaud
              Change return code and message to leverage vRO built in PowerShell Object
 =================================================================================================================================================
  Description:  This script will delete a forward and it's associated pointer dns record in a given dns zone
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Test Environment:    - PowerShell 5.1.17134.407
                              - Windows 2016 Server
  Above is my test environment, but this may potentially work with other supported versions
 -------------------------------------------------------------------------------------------------------------------------------------------------
  Pre-requisite: Elevated Rights on local powershell host and dns server
                 Modify the following variables
                  scriptdirectory
                  scriptfullpath
                  dnsservers
                  dnsreversezone
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
#@    cm-delete-dns.ps1 .... [ Common Parameters ]
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
#@    cm-delete-dns.ps1 -zone zone.local -name server001 -ip 192.168.1.100
#@    cm-delete-dns.ps1 -help
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

$scriptdirectory = "D:\library\powershell"                     # Script Full Directory Path (running from) ex: C:\temp\
$scriptfullpath = "D:\library\powershell\cm-delete-dns.ps1"    # Script Full Path with name ex: C:\temp\myscript.ps1

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

# local variable definitions
$dnsservers = @("[DNS]","[DNS]")
$dnsreversezone = "10.in-addr.arpa"
$reversefound = $false
$forwardrecord = $false
$return = @{}

# test dns server connectivity
foreach ($dnsserver in $dnsservers) {
  $testnet = Test-NetConnection $dnsserver -Port 53
  if ($testnet.TcpTestSucceeded) {
    $dnssvr = $dnsserver
    break
  }
}

if ($dnssvr) {
  $creds = Import-CliXml -Path $ScriptDirectory"\access\svcdns.xml"

  # validate reverse dns record
  if (Resolve-DnsName $ip -Server $dnssvr -ErrorAction silentlycontinue) {
    $reversefound = $true
    Write-Host "reverse dns record for ip $ip found" -ForegroundColor Green
  }

  # validate forward dns record
  if ((Resolve-DnsName "$name.$zone" -Server $dnssvr -ErrorAction silentlycontinue)) {
    $forwardrecord = $true
    Write-Host "forward dns record for $name found" -ForegroundColor Green
  }

  # delete dns record
  if ($reversefound -eq $true -and $forwardrecord -eq $true) {
    Write-Host "dns record found match the provided parameters, deleting dns record as requested" -ForegroundColor Green
    Invoke-Command -ComputerName $dnssvr -Credential $creds -ScriptBlock {
      Get-DnsServerResourceRecord -ZoneName $USING:zone -Name $USING:name -Computername $USING:dnssvr | Remove-DnsServerResourceRecord -ZoneName $USING:zone -Computername $USING:dnssvr -Confirm:$false -Force
    }
  } elseif ($reversefound -eq $false -and $forwardrecord -eq $false) {
    Write-Host "specified dns record not found, nothing to do!!!" -ForegroundColor DarkGray
  }
  # validate if the delete action cleaned up the ptr record
  sleep 5
  if (Resolve-DnsName $ip -Server $dnssvr -ErrorAction silentlycontinue) {
    Write-Warning "reverse dns record for ip $ip still present"
    if ((Resolve-DnsName $ip -Server $dnssvr).NameHost.Split(".")[0] -ieq $name) {
      Write-Host "the reverse dns record found match the requested forward record, proceeding with removal" -ForegroundColor Green
      $reversenode = $ip.split(".")[3]
      $reversenode += "."
      $reversenode += $ip.split(".")[2]
      Invoke-Command -ComputerName $dnssvr -Credential $creds -ScriptBlock {
        Get-DnsServerResourceRecord -ZoneName $USING:dnsreversezone -Computername $USING:dnssvr -Node $USING:reversenode -RRType Ptr | Remove-DnsServerResourceRecord -ZoneName $USING:dnsreversezone -ComputerName $USING:dnssvr -Force
      }
    } else {
        $msg = "reverse dns record for ip $ip found but doesn't match $name, please contact the sddc team to validate if this record is still valid or not"
        $status = 2
        $return.status = $status
        $return.msg = $msg
        Return $return
    }
  }
  # validate if the delete action cleaned up the a record
  if ((Resolve-DnsName "$name.$zone" -Server $dnssvr -ErrorAction silentlycontinue)) {
    Write-Warning "forward dns record for host $name still present"
    if ((Resolve-DnsName "$name.$zone").IPAddress -eq $ip) {
      Write-Host "the forward dns record found match the requested reverse record" -ForegroundColor Green
      Invoke-Command -ComputerName $dnssvr -Credential $creds -ScriptBlock {
        Get-DnsServerResourceRecord -ZoneName $USING:zone -Name $USING:name -Computername $USING:dnssvr | Remove-DnsServerResourceRecord -ZoneName $USING:zone -Computername $USING:dnssvr -Confirm:$false -Force
      }
    } else {
        $msg = "forward dns record for host $name found but doesn't match $ip, please contact the sddc team to validate if this record is still valid or not"
        $status = 4
        $return.status = $status
        $return.msg = $msg
        Return $return
    }
  }
} else {
  Write-Error "No DNS server(s) was/were available at the time this script ran, please validate DNS server connectivity and/or availability"
}