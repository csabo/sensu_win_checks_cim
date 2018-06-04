$compName = [System.Net.Dns]::GetHostName()
$compDomain = (Get-CimInstance Win32_ComputerSystem).Domain
$hostnameFqdn = $compName.toLower() + "." + $compDomain.toLower()

$schema = "processor"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name like '_Total'").PercentUserTime
write-host "win_perfmon_$schema,host=$hostnameFqdn %_User_Time=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name like '_Total'").PercentPrivilegedTime
write-host "win_perfmon_$schema,host=$hostnameFqdn %_Privileged_Time=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name like '_Total'").PercentProcessorTime
write-host "win_perfmon_$schema,host=$hostnameFqdn %_Processor_Time=$value"

$schema = "memory"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory).PagesPersec
write-host "win_perfmon_$schema,host=$hostnameFqdn Pages_sec=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory).PageFaultsPersec
write-host "win_perfmon_$schema,host=$hostnameFqdn Pages_Faults_sec=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory).CommittedBytes
write-host "win_perfmon_$schema,host=$hostnameFqdn Committed_Bytes=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory).AvailableBytes
write-host "win_perfmon_$schema,host=$hostnameFqdn Available_Bytes=$value"

$schema = "system"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System).Threads
write-host "win_perfmon_$schema,host=$hostnameFqdn Threads=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System).Processes
write-host "win_perfmon_$schema,host=$hostnameFqdn Processes=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
write-host "win_perfmon_$schema,host=$hostnameFqdn Processor_Queue_Length=$value"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System).SystemUpTime
write-host "win_perfmon_$schema,host=$hostnameFqdn System_Up_Time=$value"

$schema = "network"
$value=(Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_TCPv4).ConnectionsEstablished
write-host "win_perfmon_$schema,host=$hostnameFqdn Connections_Established=$value"

$rValues=(Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface).BytesReceivedPersec
$rBytes = 0
$rValues | Foreach { $rBytes+= $_}
write-host "win_perfmon_$schema,host=$hostnameFqdn Bytes_Received_sec=$rBytes"

$sValues=(Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface).BytesSentPersec
$sBytes = 0
$sValues | Foreach { $sBytes += $_}
write-host "win_perfmon_$schema,host=$hostnameFqdn Bytes_Sent_sec=$sBytes"

# disk Usage
$allDisks=(Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" | ? { $_.DeviceID -notmatch "[ab]:"})

foreach ($objDisk in $allDisks){
    $deviceId = $objDisk.deviceID -replace ":",""

    $usedSpace = [System.Math]::Round((($objDisk.Size-$objDisk.Freespace)/1MB),2)
    $availableSpace = [System.Math]::Round(($objDisk.Freespace/1MB),2)
    $usedPercentage = [System.Math]::Round(((($objDisk.Size-$objDisk.Freespace)/$objDisk.Size)*100),2)

    Write-Host "win_disk_usage,host=$hostnameFqdn,deviceid=$deviceId UsedMB=$usedSpace,FreeMB=$availableSpace,UsedPercentage=$usedPercentage"
}

# disk perf
$validDriveArray=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk | Where Name -NotLike '_Total' |Select -ExpandProperty Name)

foreach ($drive in $validDriveArray) {
  $driveLetter = $drive -Replace '[^a-zA-Z]', ''
  $perfObject=(Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name Like '$drive'")

  $value=($perfObject | Select -ExpandProperty CurrentDiskQueueLength)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Current_Disk_Queue_Length=$value"
  $value=($perfObject | Select -ExpandProperty DiskReadBytesPersec)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Disk_Read_Bytes/sec=$value"
  $value=($perfObject | Select -ExpandProperty DiskReadsPersec)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Disk_Reads/sec=$value"
  $value=($perfObject | Select -ExpandProperty DiskWriteBytesPersec)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Disk_Write_Bytes/sec=$value"
  $value=($perfObject | Select -ExpandProperty DiskWritesPersec)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Disk_Writes/sec=$value"
  $value=($perfObject | Select -ExpandProperty PercentDiskReadTime)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Percent_Disk_Read_Time=$value"
  $value=($perfObject | Select -ExpandProperty PercentDiskWriteTime)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Percent_Disk_Write_Time=$value"
  $value=($perfObject | Select -ExpandProperty PercentIdleTime)
  write-host "win_disk,host=$hostnameFqdn,deviceid=$driveLetter Percent_Idle_Time=$value"
}

# puppet last run
$yamlFilePath = "C:\ProgramData\PuppetLabs\puppet\cache\state\last_run_summary.yaml"

Function Convert-ToUnixDate ($PSdate) {
   $epoch = [timezone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970')
   (New-TimeSpan -Start $epoch -End $PSdate).TotalSeconds
}

$currentEpoch = Convert-ToUnixDate(Get-Date)
$currentEpoch = [long]$currentEpoch
$lastRunEpoch = sls "last_run" $yamlFilePath -ca | select -exp line
$lastRunEpoch = [long]$lastRunEpoch.split(':')[1]
$timeSinceLastRun = $currentEpoch - $lastRunEpoch
Write-Host "win_puppet,host=$hostnameFqdn puppet=$timeSinceLastRun"

# ram Usage
$freeMemory=(Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory
$totalMemory=(Get-CimInstance -ClassName Win32_OperatingSystem).TotalVisibleMemorySize
$usagePercent = [System.Math]::Round(((($totalMemory-$freeMemory)/$totalMemory)*100),2)
Write-host "win_memory_percent,host=$hostnameFqdn usage_percent=$usagePercent"

# page file
$pagefileSize=(Get-CimInstance -ClassName Win32_PageFileUsage).AllocatedBaseSize
$pagefileUsed=(Get-CimInstance -ClassName Win32_PageFileUsage).CurrentUsage
$pagefilePercentFree = ($pagefileSize - $pagefileUsed) / $pagefileSize * 100
$pagefilePercentUsed = 100 - $pagefilePercentFree
$pagefilePercentUsed = [math]::Round($pagefilePercentUsed,2)
Write-Host "win_memory_percent,host=$hostnameFqdn pagefile_used=$pagefilePercentUsed"