# USAGE:
#   pwsh.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File C:\\opt\\sensu\\plugins\\check-windows-cpu-load.ps1 90 95
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [int]$warning,

   [Parameter(Mandatory=$True,Position=2)]
   [int]$critical
)

$value = Get-CimInstance -ClassName win32_processor | Measure-Object -property LoadPercentage -Average | select average
$value = $value.average

if ($value -gt $critical) {
  Write-Host "WindowsCpuLoad CRITICAL: CPU at $Value%"
  exit 2
}

if ($value -gt $warning) {
  Write-Host "WindowsCpuLoad WARNING: CPU at $Value%"
  exit 1
}

else {
  Write-Host "WindowsCpuLoad OK: CPU at $Value%"
  exit 0
}
