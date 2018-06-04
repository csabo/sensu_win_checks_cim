#
#   check-windows-disk.ps1
#
# DESCRIPTION:
#   This plugin collects the Disk Usage and and compares against the WARNING and CRITICAL thresholds.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Windows
#
# DEPENDENCIES:
#   Powershell
#
# USAGE:
#   Powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File C:\\etc\\sensu\\plugins\\check-windows-disk.ps1 90 95 ab
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 sensu-plugins
#   Released under the same terms as Sensu (the MIT license); see LICENSE for details.
#
[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True,Position=1)] 
   [int]$warining,

   [Parameter(Mandatory=$True,Position=2)]
   [int]$critical,

# Example "abz"
   [Parameter(Mandatory=$False,Position=3)]
   [string]$ignore
)

if ($ignore -eq "") { $ignore = "ab" }

$exitCode = 0

$allDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" | ? { $_.DeviceID -notmatch "[$ignore]:"}

foreach ($objDisk in $allDisks) 
{ 
  $usedPercentage = [System.Math]::Round(((($objDisk.Size-$objDisk.Freespace)/$objDisk.Size)*100),2)
  
  if ($usedPercentage -gt $critical) {
    Write-Host "CheckDisk CRITICAL on disk: $($objDisk.DeviceID) $usedPercentage%"
    $exitCode = 2
  }

  elseif ($usedPercentage -gt $warining) {
    Write-Host "CheckDisk WARNING on disk: $($objDisk.DeviceID) $usedPercentage%"
    if ($exitCode -ne 2) { $exitCode = 1 }
  }
}

if ($exitCode -eq 0) {
  Write-Host "CheckDisk OK: All disk usage under $warining%"
  exit $exitCode
}

else {
  exit $exitCode
}
