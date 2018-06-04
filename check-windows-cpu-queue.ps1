# USAGE:
#   Powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File C:\\etc\\sensu\\plugins\\check-windows-cpu-queue.ps1 1 3
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [int]$warning,

   [Parameter(Mandatory=$True,Position=2)]
   [int]$critical
)

$value = (Get-CimInstance -className Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength

If ($value -gt $critical) {
  Write-Host "WindowsCpuQueue CRITICAL: Queue at $Value"
  Exit 2
}

If ($value -gt $warning) {
  Write-Host "WindowsCpuQueue WARNING: Queue at $Value"
  Exit 1
}

Else {
  Write-Host "WindowsCpuQueue OK: Queue at $Value"
  Exit 0
}