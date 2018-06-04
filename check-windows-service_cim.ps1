# USAGE:
#   pwsh.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File C:\\etc\\sensu\\plugins\\check-windows-service.ps1 $serviceDisplayNameString $ExclusionArray
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$serviceName,

  [Parameter(Mandatory=$False,Position=2)]
   [string[]]$exclude
)
$stoppedServicesArray = @()

try {
  $activeServices = Get-CimInstance -ClassName Win32_Service -Filter "Name like '$serviceName' AND StartMode = 'Auto'"
} catch {
  Write-Host "WindowsServiceStatus CRITICAL: Failed to retrieve services. Error: $($_.Exception.Message)"
  Exit 2
}

foreach ($service in $activeServices | Where-Object {$exclude -notcontains $_.DisplayName}) {
  if ($service.State -eq "Stopped") {
    $stoppedServicesArray += $service.DisplayName
  }
}

if ($stoppedServicesArray.length -gt 0) {
  Write-Host "WindowsServiceStatus CRITICAL: The following services are stopped $stoppedServicesArray"
  exit 2
}
else {
    Write-Host "WindowsServiceStatus OK: All required services running"
    exit 0
}