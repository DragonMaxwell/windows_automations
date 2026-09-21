# Aggressively reduces Windows 11 telemetry, diagnostics, feedback, activity history, and data collection without disabling Windows Update, Defender, Store, or activation.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

Write-Host ""

$ErrorActionPreference = "Continue"

$SystemPolicy = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Write-Host "Applying configuration: $SystemPolicy" -ForegroundColor Yellow
New-Item -Path $SystemPolicy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $SystemPolicy -Name "NoConnectedUser" -PropertyType DWord -Value 3 -Force -ErrorAction SilentlyContinue | Out-Null

$MicrosoftAccountPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftAccount"
Write-Host "Applying configuration: $MicrosoftAccountPolicy" -ForegroundColor Yellow
New-Item -Path $MicrosoftAccountPolicy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $MicrosoftAccountPolicy -Name "DisableUserAuth" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

$DataCollection = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Write-Host "Applying configuration: $DataCollection" -ForegroundColor Yellow
New-Item -Path $DataCollection -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection -Name "AllowTelemetry" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection -Name "LimitDiagnosticLogCollection" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection -Name "LimitDumpCollection" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection -Name "DisableDiagnosticDataViewer" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection -Name "DisableTelemetryOptInSettingsUx" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection -Name "AllowDeviceNameInTelemetry" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$DataCollection2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
Write-Host "Applying configuration: $DataCollection2" -ForegroundColor Yellow
New-Item -Path $DataCollection2 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection2 -Name "AllowTelemetry" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $DataCollection2 -Name "MaxTelemetryAllowed" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$services = @(
    "DiagTrack",
    "dmwappushservice"
)

foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue

    Write-Host "Disabling service: $service" -ForegroundColor Yellow

    if ($null -ne $svc) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

$WER = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
New-Item -Path $WER -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $WER -Name "Disabled" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $WER -Name "LoggingDisabled" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

if (Get-Command Disable-WindowsErrorReporting -ErrorAction SilentlyContinue) {
    Disable-WindowsErrorReporting -ErrorAction SilentlyContinue | Out-Null
}

$SystemPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
New-Item -Path $SystemPolicy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $SystemPolicy -Name "EnableActivityFeed" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $SystemPolicy -Name "PublishUserActivities" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $SystemPolicy -Name "UploadUserActivities" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$Privacy = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"
New-Item -Path $Privacy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Privacy -Name "TailoredExperiencesWithDiagnosticDataEnabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$Advertising = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
New-Item -Path $Advertising -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Advertising -Name "Enabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$Feedback = "HKCU:\Software\Microsoft\Siuf\Rules"
New-Item -Path $Feedback -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Feedback -Name "NumberOfSIUFInPeriod" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $Feedback -Name "PeriodInNanoSeconds" -PropertyType QWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$InputPersonalization = "HKCU:\Software\Microsoft\InputPersonalization"
New-Item -Path $InputPersonalization -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $InputPersonalization -Name "RestrictImplicitInkCollection" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $InputPersonalization -Name "RestrictImplicitTextCollection" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

$TrainedData = "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"
New-Item -Path $TrainedData -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $TrainedData -Name "HarvestContacts" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$PersonalizationSettings = "HKCU:\Software\Microsoft\Personalization\Settings"
New-Item -Path $PersonalizationSettings -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $PersonalizationSettings -Name "AcceptedPrivacyPolicy" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$ContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
New-Item -Path $ContentDelivery -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338393Enabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-353694Enabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-353696Enabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $ContentDelivery -Name "SubscribedContent-338388Enabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $ContentDelivery -Name "SystemPaneSuggestionsEnabled" -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

$CloudContent = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
New-Item -Path $CloudContent -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $CloudContent -Name "DisableWindowsConsumerFeatures" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $CloudContent -Name "DisableTailoredExperiencesWithDiagnosticData" -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null

$tasks = @(
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" },
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "PcaPatchDbTask" },
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" },
    @{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector" },
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient" },
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClientOnScenarioDownload" }
)

foreach ($task in $tasks) {
    $task_name = $task.Name

    Write-Host "Disabling scheduled task: $task_name" -ForegroundColor Yellow

    $existingTask = Get-ScheduledTask `
        -TaskPath $task.Path `
        -TaskName $task.Name `
        -ErrorAction SilentlyContinue

    if ($null -ne $existingTask) {
        Disable-ScheduledTask `
            -TaskPath $task.Path `
            -TaskName $task.Name `
            -ErrorAction SilentlyContinue | Out-Null
    }
}

if (Get-Command gpupdate.exe -ErrorAction SilentlyContinue) {
    Write-Host "Updating Group Policy." -ForegroundColor Yellow
    & gpupdate.exe /target:computer /force | Out-Null
    & gpupdate.exe /target:user /force | Out-Null
}

Write-Host ""
Write-Host "Privacy configuration applied." -ForegroundColor Green
Write-Host "Restart Windows to complete the changes." -ForegroundColor Yellow
exit 0