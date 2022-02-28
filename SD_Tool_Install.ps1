#SD Tool Install
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
Get-Service wuauserv | Restart-Service
dism.exe /online /add-capability /capabilityname:Rstat.ActiveDirectory.DS-LDS.Tools~~~0.0.1.0
dism.exe /online /add-capability /capabilityname:Rstat.ServerManager.Tools~~~0.0.1.0
dism.exe /online /add-capability /capabilityname:Rstat.GroupPolicy.Management.Tools~~~0.0.1.0
dism.exe /online /add-capability /capabilityname:Rstat.Dns.Tools~~~0.0.1.0
dism.exe /online /add-capability /capabilityname:Rstat.DHCP.Tools~~~0.0.1.0
dism.exe /online /add-capability /capabilityname:Rstat.BitLocker.Recovery.Tools~~~0.0.1.0
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 1
Get-Service wuauserv | Restart-Service
Write-Host "Exiting Script" -ForegroundColor Cyan