# USAGE:
#   Powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File C:\\etc\\sensu\\plugins\\check-windows-pagefile.ps1 85 98
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [int]$warning,

   [Parameter(Mandatory=$True,Position=2)]
   [int]$critical
)

try {
  $pagefileUsed=(Get-CimInstance -classname Win32_PageFileUsage).CurrentUsage
  $pagefileSize=(Get-CimInstance -classname Win32_PageFileUsage).AllocatedBaseSize
  $pagefilePercentFree = ($pagefileSize - $pagefileUsed) / $pagefileSize * 100
  $pagefilePercentUsed = [System.Math]::Round((100 - $pagefilePercentFree),2)
} catch {
  Write-Host "PageFileUsage WARNING: $_.Exception.Message"
  exit 1 
}

if ($pagefilePercentUsed -gt $critical) {
  Write-Host "PageFileUsage CRITICAL: currently $pagefilePercentUsed% used"
  exit 2
}

if ($pagefilePercentUsed -gt $warning) {
  Write-Host "PageFileUsage WARNING: currently $pagefilePercentUsed% used"
  exit 1
}

else {
  Write-Host "PageFileUsage OK: currently $pagefilePercentUsed% used"
  exit 0
}