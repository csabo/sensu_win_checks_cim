# USAGE:
#   pwsh.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File C:\\opt\\sensu\\plugins\\check-windows-ram.ps1 90 95

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [int]$warning,

   [Parameter(Mandatory=$True,Position=2)]
   [int]$critical
)

$memory = (Get-CimInstance -ClassName Win32_OperatingSystem)
$value = [System.Math]::Round(((($memory.TotalVisiblememorySize-$memory.FreePhysicalmemory)/$memory.TotalVisiblememorySize)*100),2)

if ($value -gt $critical) {
  Write-Host "WindowsRAMLoad CRITICAL: RAM at $value%"
  exit 2 
}
if ($value -gt $warning) {
  Write-Host "WindowsRAMLoad WARNING: RAM at $value%"
}
else {
  Write-Host "WindowsRAMLoad OK: RAM at $value%"
  exit 0
}
