# Reorganizes the folder view in File Explorer so that all folders always use the same layout, regardless of their contents.
$bagsPath = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'
$bagMruPath = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU'
$allFolders = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell'

Remove-Item -Path $bagsPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $bagMruPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -Path $allFolders -Force | Out-Null
New-ItemProperty -Path $allFolders -Name 'FolderType' -PropertyType String -Value 'NotSpecified' -Force | Out-Null
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process "$env:WINDIR\explorer.exe" -WindowStyle Hidden }

# Enables auto-login for the current user; it can be configured through "control userpasswords2".
$winlogonPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

New-ItemProperty -Path $winlogonPath -Name 'AutoAdminLogon' -PropertyType String -Value '1' -Force | Out-Null
New-ItemProperty -Path $winlogonPath -Name 'DefaultUserName' -PropertyType String -Value $env:USERNAME -Force | Out-Null
New-ItemProperty -Path $winlogonPath -Name 'DefaultDomainName' -PropertyType String -Value $env:COMPUTERNAME -Force | Out-Null