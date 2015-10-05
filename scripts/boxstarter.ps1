$user = "packer"
$pass = "P@ssw0rd"
$WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon
Remove-ItemProperty -Path $WinlogonPath -Name DefaultUserName

Import-Module a:\functions.psm1
Get-Boxstarter -Force

$cred = New-Object System.Management.Automation.PSCredential ($user, (ConvertTo-SecureString $pass -AsPlainText -Force))

Import-Module $env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1
Install-BoxstarterPackage -PackageName a:\package.ps1 -Credential $cred
