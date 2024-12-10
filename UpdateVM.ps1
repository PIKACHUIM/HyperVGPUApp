# 参数：虚拟机名称
param(
    [string]$VMName
    [string]$GPUName
)

if (-not $VMName) {
    Write-Error "Please provide a VM name."
    exit
}

if (-not $GPUName) {
    Write-Error "Please provide a GPU name."
    exit
}
Import-Module $PSSCriptRoot\CopyFile.psm1

$VM = Get-VM -Name $VMName
$VHDPath = (Get-VMHardDiskDrive -VM $VM | Select-Object -First 1).Path
Mount-VHD -Path $VHDPath
$Disk = Get-Disk | Where-Object { $_.Location -eq $VHDPath }
$Partition = Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.Type -eq 'NTFS' -or ($_.Type -eq 'Basic')} | Select-Object -First 1
$DriveLetter = $Partition.DriveLetter
Add-VMGpuPartitionAdapterFiles -GPUName $GPUName -DriveLetter $DriveLetter
Dismount-VHD -Path $VHDPath -ErrorAction Stop