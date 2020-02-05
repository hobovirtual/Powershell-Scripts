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
  Script:     cm-create-dns.ps1
 =================================================================================================================================================
  Author:  Christian Renaud
  Date:    2020/01/06
  -------------------------------------------------
  Updates     
  -------------------------------------------------
  2020/01/28  by Christian Renaud
              Change return code and message to leverage vRO built in PowerShell Object
 =================================================================================================================================================
  Description:  This script will create a forward and it's associated pointer dns record in a given dns zone
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

$scriptdirectory = "D:\library\powershell"                     # Script Full Directory Path (running from) ex: C:\temp\
$scriptfullpath = "D:\library\powershell\cm-create-dns.ps1"    # Script Full Path with name ex: C:\temp\myscript.ps1

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
    Write-Warning "reverse dns record for ip $ip found"
  }

  # validate forward dns record
  if ((Resolve-DnsName "$name.$zone" -Server $dnssvr -ErrorAction silentlycontinue)) {
    $forwardrecord = $true
    Write-Warning "forward dns record for $name found"
  }

  # create dns record
  if ($reversefound -eq $false -and $forwardrecord -eq $false) {
    Write-Host "no previous/stale dns record found, creating dns record as requested" -ForegroundColor Green
    Invoke-Command -ComputerName $dnssvr -Credential $creds -ScriptBlock {
      Add-DnsServerResourceRecordA $USING:zone -Name $USING:name -IPv4Address $USING:ip -CreatePtr -ComputerName $USING:dnssvr
    } 
  } else {
    if ($reversefound -eq $true) {
    Write-Host "a reverse dns record was found, running validation on this record" -ForegroundColor DarkGray
      # validate if the current reverse record match the requested forward record
      if ((Resolve-DnsName $ip -Server $dnssvr).NameHost.Split(".")[0] -ieq $name) {
        Write-Host "the reverse dns record found match the requested forward record" -ForegroundColor Green
        
        if ($forwardrecord -eq $false) {
          Write-Host "forward record missing....proceeding with the creation of the missing record"
          Invoke-Command -ComputerName $dnssvr -Credential $creds -ScriptBlock {
            Add-DnsServerResourceRecordA $USING:zone -Name $USING:name -IPv4Address $USING:ip -ComputerName $USING:dnssvr
          }
        }

      } else {
          $msg = "reverse dns record for ip $ip found but doesn't match $name, please contact the sddc team to validate if this record is still valid or not. as per corporate policy this condition will fail a deployment"
          $status = 2
          $return.status = $status
          $return.msg = $msg
          Return $return
      }
    } 
    
    if ($forwardrecord -eq $true) {
      Write-Host "a forward dns record was found, running validation on this record" -ForegroundColor DarkGray
      if ((Resolve-DnsName "$name.$zone").IPAddress -eq $ip) {
        Write-Host "the forward dns record found match the requested reverse record" -ForegroundColor Green
        
        if ($reversefound -eq $false) {
          Write-Host "reverse record missing....proceeding with the creation of the missing record"
          # create ptr record
          $ptr = $ip.split(".")[3]
          $ptr += "."
          $ptr += $ip.split(".")[2]
          $ptrdomain = $name
          $ptrdomain += "."
          $ptrdomain += $zone
          Invoke-Command -ComputerName $dnssvr -Credential $creds -ScriptBlock {
            Add-DnsServerResourceRecordPtr -Name $USING:ptr -ZoneName $USING:dnsreversezone -PtrDomainName $USING:ptrdomain -ComputerName $USING:dnssvr
          }
        }
      } else {
          $msg = "forward dns record for $name found but doesn't match the ip $ip provided, please contact the sddc team to validate if this record is still valid or not. as per corporate policy this condition will fail a deployment"
          $status = 4
          $return.status = $status
          $return.msg = $msg
          Return $return
      }
    }
  }
} else {
  Write-Host "No DNS server(s) was/were available at the time this script ran, please validate DNS server connectivity and/or availability"
}