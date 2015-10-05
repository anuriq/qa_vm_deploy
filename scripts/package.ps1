Enable-RemoteDesktop
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Write-BoxstarterMessage "Removing page file"
$pageFileMemoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $pageFileMemoryKey -Name PagingFiles -Value ""

Update-ExecutionPolicy -Policy Unrestricted

Write-BoxstarterMessage "Installing dotNet Framework 4.5.1..."
cinst "dotnet4.5.1" -y

Write-BoxstarterMessage "Installing Windows features..."
Install-WindowsFeature -ConfigurationFilePath a:\windows_features.xml

Write-BoxstarterMessage "Installing required packages..."
cinst jre8 -y
cinst adobereader -y
cinst tightvnc -y

Write-BoxstarterMessage "Removing unused features..."
Remove-WindowsFeature -Name 'Powershell-ISE'
Get-WindowsFeature | ? { $_.InstallState -eq 'Available' } | Uninstall-WindowsFeature -Remove

Write-BoxstarterMessage "Disabling screensaver..."
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -Value 0
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "SCRNSAVE.EXE" -Value ""
	
#Install-WindowsUpdate -AcceptEula
if(Test-PendingReboot) { Invoke-Reboot }

Write-BoxstarterMessage "Cleaning SxS..."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

@(
    "$env:localappdata\Nuget",
    "$env:localappdata\temp\*",
    "$env:windir\logs",
    "$env:windir\panther",
    "$env:windir\temp\*",
    "$env:windir\winsxs\manifestcache"
) | % {
        if(Test-Path $_) {
            Write-BoxstarterMessage "Removing $_"
            Takeown /d Y /R /f $_
            Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
            Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

Write-BoxstarterMessage "defragging..."
Optimize-Volume -DriveLetter C

Write-BoxstarterMessage "0ing out empty space..."
a:\sdelete.exe /accepteula -z c:

mkdir C:\Windows\Panther\Unattend
copy-item a:\postunattend.xml C:\Windows\Panther\Unattend\unattend.xml

Write-BoxstarterMessage "Recreate pagefile after sysprep"
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
$System.AutomaticManagedPagefile = $true
$System.Put()

Write-BoxstarterMessage "Setting up winrm"
Enable-WSManCredSSP -Force -Role Server

Enable-PSRemoting -Force -SkipNetworkProfileCheck
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
