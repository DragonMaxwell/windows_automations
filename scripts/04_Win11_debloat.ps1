# Windows 11 Pro 25H2 - Debloat / Privacy / Performance policy
# Generated from the user's decision matrix.
# Run as Administrator.
# The script is intentionally resilient: each step is isolated, errors are reported,
# execution continues, and the window waits for ENTER at the end.

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 78) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 78) -ForegroundColor Cyan
}

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "[RUN ] $Name" -ForegroundColor Yellow

    try {
        & $Action
        Write-Host "[ OK ] $Name" -ForegroundColor Green
    }
    catch {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        Write-Host ("       " + $_.Exception.Message) -ForegroundColor DarkRed
    }
}

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [switch]$IgnoreExitCode
    )

    & $FilePath @Arguments
    $code = $LASTEXITCODE

    if (-not $IgnoreExitCode -and $code -ne 0) {
        throw "$FilePath exited with code $code"
    }

    return $code
}

function Set-RegDword {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force -ErrorAction Stop | Out-Null
}

function Set-RegString {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force -ErrorAction Stop | Out-Null
}

function Disable-ServiceSafe {
    param([string]$Name)

    $services = @(Get-Service -Name $Name -ErrorAction SilentlyContinue)

    if ($services.Count -eq 0) {
        Write-Host "       Service not present: $Name" -ForegroundColor DarkGray
        return
    }

    foreach ($service in $services) {
        try {
            if ($service.Status -ne "Stopped") {
                Stop-Service -Name $service.Name -Force -ErrorAction Stop
            }
        }
        catch {
            Write-Host "       Could not stop $($service.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }

        try {
            Set-Service -Name $service.Name -StartupType Disabled -ErrorAction Stop
        }
        catch {
            Write-Host "       Set-Service failed for $($service.Name); trying registry Start=4." -ForegroundColor DarkYellow
            $serviceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($service.Name)"
            if (Test-Path $serviceKey) {
                Set-RegDword -Path $serviceKey -Name "Start" -Value 4
            }
        }
    }
}

function Disable-ServiceTemplate {
    param([string]$BaseName)

    # Disable the service template for per-user services such as OneSyncSvc_xxxxx.
    $templateKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$BaseName"
    if (Test-Path $templateKey) {
        try {
            Set-RegDword -Path $templateKey -Name "Start" -Value 4
        }
        catch {
            Write-Host "       Could not disable template ${BaseName}: $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }

    $instances = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $BaseName -or $_.Name -like "$BaseName`_*" })
    foreach ($service in $instances) {
        try {
            Stop-Service -Name $service.Name -Force -ErrorAction Stop
        }
        catch {
            Write-Host "       Could not stop $($service.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }

        $instanceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($service.Name)"
        if (Test-Path $instanceKey) {
            try {
                Set-RegDword -Path $instanceKey -Name "Start" -Value 4
            }
            catch {
                Write-Host "       Could not set Start=4 for $($service.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
    }
}

function Disable-ScheduledTaskSafe {
    param([string]$TaskPath, [string]$TaskName)

    $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($null -eq $task) {
        Write-Host "       Task not present: $TaskPath$TaskName" -ForegroundColor DarkGray
        return
    }

    Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null
}

function Remove-AppxPattern {
    param([string]$Pattern)

    $found = $false

    $packages = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $Pattern })
    foreach ($pkg in $packages) {
        $found = $true
        Write-Host "       Removing installed AppX: $($pkg.Name)" -ForegroundColor DarkCyan
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        }
        catch {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
            }
            catch {
                Write-Host "       Installed package removal failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
    }

    $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $Pattern })
    foreach ($pkg in $provisioned) {
        $found = $true
        Write-Host "       Removing provisioned AppX: $($pkg.DisplayName)" -ForegroundColor DarkCyan
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -AllUsers -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "       Provisioned package removal failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }

    if (-not $found) {
        Write-Host "       Package not present: $Pattern" -ForegroundColor DarkGray
    }
}

function Remove-OneDrive {
    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $candidates = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
    )

    $setup = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($setup) {
        Write-Host "       Using: $setup" -ForegroundColor DarkCyan
        $p = Start-Process -FilePath $setup -ArgumentList "/uninstall" -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -ne 0) {
            Write-Host "       OneDrive uninstaller returned code $($p.ExitCode)." -ForegroundColor DarkYellow
        }
    }
    else {
        Write-Host "       OneDriveSetup.exe not found." -ForegroundColor DarkGray
    }

    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Value 1
}

function Remove-Edge {
    # WebView2 Runtime is intentionally NOT touched.
    $roots = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application",
        "$env:ProgramFiles\Microsoft\Edge\Application"
    )

    $setup = $null

    foreach ($root in $roots) {
        if (-not (Test-Path $root)) {
            continue
        }

        $candidate = Get-ChildItem -Path $root -Filter setup.exe -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "\\Installer\\setup\.exe$" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1

        if ($candidate) {
            $setup = $candidate.FullName
            break
        }
    }

    if (-not $setup) {
        Write-Host "       Microsoft Edge installer was not found." -ForegroundColor DarkGray
        return
    }

    Write-Host "       Edge setup: $setup" -ForegroundColor DarkCyan
    $p = Start-Process -FilePath $setup -ArgumentList "--uninstall --system-level --force-uninstall --verbose-logging" -Wait -PassThru -WindowStyle Hidden

    if ($p.ExitCode -ne 0) {
        throw "Edge uninstaller returned code $($p.ExitCode). Windows may be preventing Edge removal."
    }
}

function Remove-KnownOemBloat {
    # Conservative list only. Hardware hotkey/fan/battery services are NOT targeted.
    $patterns = @(
        "*Acer Care Center*",
        "*Acer Collection*",
        "*Acer Product Registration*",
        "*Acer UEIP*",
        "*Dell SupportAssist*",
        "*Dell Data Vault*",
        "*Dell Analytics*",
        "*HP Support Assistant*",
        "*HP Touchpoint Analytics*"
    )

    $uninstallRoots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = @(Get-ItemProperty $uninstallRoots -ErrorAction SilentlyContinue | Where-Object {
        $name = $_.DisplayName
        if ([string]::IsNullOrWhiteSpace($name)) { return $false }
        foreach ($pattern in $patterns) {
            if ($name -like $pattern) { return $true }
        }
        return $false
    })

    if ($apps.Count -eq 0) {
        Write-Host "       No known OEM support/telemetry packages detected." -ForegroundColor DarkGray
        return
    }

    foreach ($app in $apps) {
        Write-Host "       Detected OEM package: $($app.DisplayName)" -ForegroundColor DarkCyan

        $cmd = $app.QuietUninstallString
        if ([string]::IsNullOrWhiteSpace($cmd)) {
            $cmd = $app.UninstallString
        }

        if ([string]::IsNullOrWhiteSpace($cmd)) {
            Write-Host "       No uninstall command; skipped." -ForegroundColor DarkYellow
            continue
        }

        try {
            if ($cmd -match '^\s*"([^"]+)"\s*(.*)$') {
                $exe = $matches[1]
                $args = $matches[2]
            }
            elseif ($cmd -match '^\s*(\S+)\s*(.*)$') {
                $exe = $matches[1]
                $args = $matches[2]
            }
            else {
                Write-Host "       Could not parse uninstall command; skipped." -ForegroundColor DarkYellow
                continue
            }

            if ($exe -match '(?i)msiexec(\.exe)?$' -and $args -match '(?i)/I') {
                $args = $args -replace '(?i)/I', '/X'
                if ($args -notmatch '(?i)/qn') {
                    $args = "$args /qn /norestart"
                }
            }

            $p = Start-Process -FilePath $exe -ArgumentList $args -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
            Write-Host "       Uninstaller exit code: $($p.ExitCode)" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "       OEM uninstall failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
}

# ---------------------------------------------------------------------------
# Administrator check / self elevation
# ---------------------------------------------------------------------------

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges are required. Requesting elevation..." -ForegroundColor Yellow

    try {
        $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList -ErrorAction Stop
    }
    catch {
        Write-Host "Elevation failed: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press ENTER to close"
    }

    exit
}

Clear-Host
Write-Host "Windows 11 Pro 25H2 - Privacy / Debloat / Performance policy" -ForegroundColor White
Write-Host "Errors do NOT stop the script. The window remains open at the end." -ForegroundColor Gray

# ---------------------------------------------------------------------------
# 1. TELEMETRY / DIAGNOSTICS / PRIVACY
# ---------------------------------------------------------------------------

Write-Section "1. TELEMETRY, DIAGNOSTICS AND PRIVACY"

Invoke-Step "Set diagnostic-data policies to minimum" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DisableOneSettingsDownloads" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1
}

Invoke-Step "Disable advertising ID" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
}

Invoke-Step "Disable tailored experiences" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1
}

Invoke-Step "Disable activity history" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
}

Invoke-Step "Disable consumer experiences, suggestions and Spotlight content" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableThirdPartySuggestions" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightOnActionCenter" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightOnSettings" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightWindowsWelcomeExperience" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0
}

Invoke-Step "Disable telemetry and error-reporting services" {
    Disable-ServiceSafe "DiagTrack"
    Disable-ServiceSafe "dmwappushservice"
    Disable-ServiceSafe "WerSvc"
}

Invoke-Step "Disable Diagnostic Service Host and Diagnostic System Host" {
    Disable-ServiceSafe "WdiServiceHost"
    Disable-ServiceSafe "WdiSystemHost"
}

Invoke-Step "Disable telemetry / feedback scheduled tasks" {
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Application Experience\" "Microsoft Compatibility Appraiser"
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Application Experience\" "PcaPatchDbTask"
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Customer Experience Improvement Program\" "Consolidator"
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Customer Experience Improvement Program\" "UsbCeip"
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Feedback\Siuf\" "DmClient"
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Feedback\Siuf\" "DmClientOnScenarioDownload"
    Disable-ScheduledTaskSafe "\Microsoft\Windows\Windows Error Reporting\" "QueueReporting"
}

# ---------------------------------------------------------------------------
# 2. REMOVE SELECTED APPX / CONSUMER APPS
# ---------------------------------------------------------------------------

Write-Section "2. REMOVE SELECTED APPX / CONSUMER APPS"

$appPatterns = @(
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.MicrosoftOfficeHub",
    "MSTeams",
    "MicrosoftTeams",
    "Microsoft.OutlookForWindows",
    "Microsoft.Copilot",
    "Microsoft.GamingApp",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.GamingServices",
    "Clipchamp.Clipchamp",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.YourPhone",
    "MicrosoftCorporationII.QuickAssist",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsMaps",
    "Microsoft.BingWeather",
    "Microsoft.BingNews",
    "Microsoft.People",
    "microsoft.windowscommunicationsapps",
    "Microsoft.ZuneMusic",
    "Microsoft.ScreenSketch",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Windows.DevHome"
)

foreach ($pattern in $appPatterns) {
    Invoke-Step "Remove AppX $pattern" {
        Remove-AppxPattern $pattern
    }
}

Invoke-Step "Remove OneDrive and block OneDrive sync" {
    Remove-OneDrive
}

Invoke-Step "Remove Microsoft Edge but preserve WebView2 Runtime" {
    Remove-Edge
}

# ---------------------------------------------------------------------------
# 3. COPILOT, WIDGETS, GAMING
# ---------------------------------------------------------------------------

Write-Section "3. COPILOT, WIDGETS AND GAMING"

Invoke-Step "Disable Copilot by policy" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
}

Invoke-Step "Disable Widgets without removing Windows Web Experience Pack" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0
}

Invoke-Step "Disable Game DVR and background capture" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
    Set-RegDword -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
}

Invoke-Step "Disable Xbox services selected for removal" {
    Disable-ServiceSafe "XblAuthManager"
    Disable-ServiceSafe "XblGameSave"
    Disable-ServiceSafe "GamingServices"
    Disable-ServiceSafe "GamingServicesNet"
}

# XboxGipSvc is intentionally kept.

# ---------------------------------------------------------------------------
# 4. SERVICES SELECTED AS DISABLE / REMOVE
# ---------------------------------------------------------------------------

Write-Section "4. SERVICES SELECTED AS DISABLE / REMOVE"

$disabledServices = @(
    "Spooler",
    "Fax",
    "WwanSvc",
    "SSDPSRV",
    "upnphost",
    "RemoteRegistry",
    "RemoteAccess",
    "TermService",
    "WbioSrvc",
    "TabletInputService",
    "CDPSvc",
    "wlidsvc",
    "TokenBroker",
    "wisvc",
    "MapsBroker",
    "RetailDemo",
    "SCardSvr",
    "WpcMonSvc"
)

foreach ($serviceName in $disabledServices) {
    Invoke-Step "Disable service $serviceName" {
        Disable-ServiceSafe $serviceName
    }
}

Invoke-Step "Disable per-user Sync Host services" {
    Disable-ServiceTemplate "OneSyncSvc"
}

Invoke-Step "Disable per-user User Data Access services" {
    Disable-ServiceTemplate "UserDataSvc"
}

Invoke-Step "Disable per-user Contact Data services" {
    Disable-ServiceTemplate "PimIndexMaintenanceSvc"
}

# ---------------------------------------------------------------------------
# 5. OEM SUPPORT / OEM TELEMETRY
# ---------------------------------------------------------------------------

Write-Section "5. OEM SUPPORT / OEM TELEMETRY"

Invoke-Step "Remove known OEM support and telemetry packages" {
    Remove-KnownOemBloat
}

Write-Host ""
Write-Host "Third-party antivirus trials are not blindly removed by product-name wildcard." -ForegroundColor DarkYellow
Write-Host "This avoids accidentally uninstalling a deliberately installed licensed antivirus." -ForegroundColor DarkYellow

# ---------------------------------------------------------------------------
# 6. IDLE LOCK / AUTOMATIC LOCK REMOVAL
# ---------------------------------------------------------------------------

Write-Section "6. DISABLE IDLE LOCK / AUTOMATIC LOCK"

Invoke-Step "Disable machine inactivity lock" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -Value 0
}

Invoke-Step "Disable screen saver and secure screen saver for current user" {
    Set-RegString -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "0"
    Set-RegString -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -Value "0"
    Set-RegString -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "0"
}

Invoke-Step "Disable screen-saver lock by policy for current user" {
    Set-RegString -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "0"
    Set-RegString -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -Value "0"
}

Invoke-Step "Disable lock requirement after sleep on AC/DC" {
    Invoke-Native -FilePath "powercfg.exe" -Arguments @("/SETACVALUEINDEX", "SCHEME_CURRENT", "SUB_NONE", "CONSOLELOCK", "0") -IgnoreExitCode | Out-Null
    Invoke-Native -FilePath "powercfg.exe" -Arguments @("/SETDCVALUEINDEX", "SCHEME_CURRENT", "SUB_NONE", "CONSOLELOCK", "0") -IgnoreExitCode | Out-Null
    Invoke-Native -FilePath "powercfg.exe" -Arguments @("/SETACTIVE", "SCHEME_CURRENT") -IgnoreExitCode | Out-Null
}

Invoke-Step "Disable automatic sleep caused only by idle timeout" {
    Invoke-Native -FilePath "powercfg.exe" -Arguments @("/CHANGE", "standby-timeout-ac", "0") -IgnoreExitCode | Out-Null
    Invoke-Native -FilePath "powercfg.exe" -Arguments @("/CHANGE", "standby-timeout-dc", "0") -IgnoreExitCode | Out-Null
}

# ---------------------------------------------------------------------------
# 7. KEEP LIST - INTENTIONALLY UNTOUCHED
# ---------------------------------------------------------------------------

Write-Section "7. COMPONENTS INTENTIONALLY KEPT"

$kept = @(
    "Windows Defender / Windows Security / Security Center / Firewall / SmartScreen",
    "Windows Search and SearchIndexer",
    "Diagnostic Policy Service (DPS)",
    "Microsoft Store / App Installer / AppXSvc / ClipSVC / StateRepository",
    "Microsoft Edge WebView2 Runtime",
    "Windows Web Experience Pack",
    "Camera / Photos / Notepad / Paint / Calculator",
    "Windows Terminal / PowerShell 7 / Windows PowerShell 5.1",
    "WSL / Virtual Machine Platform / Hyper-V / Windows Sandbox / Containers",
    "Bluetooth / WLAN / core networking services",
    "Function Discovery Provider Host / Function Discovery Resource Publication",
    "RasMan / OpenSSH Authentication Agent",
    "Windows Update / Update Orchestrator / BITS / Delivery Optimization",
    "TrustedInstaller / Windows Installer / CryptSvc",
    "Task Scheduler / Event Log / WMI / RPC / DCOM / COM+",
    "User Profile Service / Group Policy Client",
    "SysMain / Prefetch / Storage / Optimize Drives",
    "Windows Backup / VSS / System Restore",
    "Windows Hello / Credential Manager / Secondary Logon",
    "Sensor Service / Geolocation / Windows Time / Time Zone Auto Update",
    "Windows Push Notifications / Clipboard User Service",
    "Windows Image Acquisition",
    "OEM hotkey / fan / battery hardware services"
)

foreach ($item in $kept) {
    Write-Host "       KEEP: $item" -ForegroundColor DarkGreen
}

# ---------------------------------------------------------------------------
# 8. APPLY POLICIES / FINAL STATUS
# ---------------------------------------------------------------------------

Write-Section "8. APPLY POLICY CHANGES"

Invoke-Step "Refresh Group Policy" {
    Invoke-Native -FilePath "gpupdate.exe" -Arguments @("/force") -IgnoreExitCode | Out-Null
}

Write-Host ""
Write-Host "Finished." -ForegroundColor Green
Write-Host ""
Write-Host "Important:" -ForegroundColor Yellow
Write-Host " - The script continued past individual errors instead of aborting." -ForegroundColor Gray
Write-Host " - Remote Desktop Services (TermService) is disabled because your table explicitly marked it DESABILITAR." -ForegroundColor Gray
Write-Host " - Windows Web Experience Pack and Edge WebView2 Runtime were intentionally preserved." -ForegroundColor Gray
Write-Host " - Automatic idle lock, secure screen saver, and idle sleep were disabled." -ForegroundColor Gray
Write-Host " - A restart is recommended after reviewing the results above." -ForegroundColor Gray
Write-Host ""
Read-Host "Press ENTER to close this window"
