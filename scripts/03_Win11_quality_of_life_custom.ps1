# Windows 11 - QoL privacy tweaks
# Applies ONLY:
# 1) Disable Delivery Optimization P2P while keeping Windows Update functional.
# 2) Disable Start menu recommendations/suggestions/promotional content.
# 3) Disable web/Bing search integration in Start/Search while keeping local Windows Search.
# 4) Disable promotional notifications, Welcome Experience, setup suggestions,
#    and Microsoft/OneDrive promotional prompts.
#
# Run as Administrator.
# Errors are handled per step, execution continues, and the window stays open.

$ErrorActionPreference = "Continue"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor Cyan
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

# Self elevation
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges are required. Requesting elevation..." -ForegroundColor Yellow

    try {
        $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $args -ErrorAction Stop
    }
    catch {
        Write-Host "Elevation failed: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press ENTER to close"
    }

    exit
}

Clear-Host
Write-Host "Windows 11 - Selected QoL privacy tweaks" -ForegroundColor White
Write-Host "Only the four requested groups will be changed." -ForegroundColor Gray

# 1. Delivery Optimization - disable P2P only
Write-Section "1. DELIVERY OPTIMIZATION - DISABLE P2P ONLY"

Invoke-Step "Set Delivery Optimization download mode to HTTP only" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0
}

# 2. Start menu suggestions / recommendations / promotional content
Write-Section "2. START MENU SUGGESTIONS AND RECOMMENDATIONS"

Invoke-Step "Disable Start recommendations and suggested content" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Recommendations" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0
}

Invoke-Step "Disable content-delivery suggestions and silent promotional installs" {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

    Set-RegDword -Path $path -Name "ContentDeliveryAllowed" -Value 0
    Set-RegDword -Path $path -Name "OemPreInstalledAppsEnabled" -Value 0
    Set-RegDword -Path $path -Name "PreInstalledAppsEnabled" -Value 0
    Set-RegDword -Path $path -Name "PreInstalledAppsEverEnabled" -Value 0
    Set-RegDword -Path $path -Name "SilentInstalledAppsEnabled" -Value 0
    Set-RegDword -Path $path -Name "SystemPaneSuggestionsEnabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-338388Enabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-338389Enabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-353694Enabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-353696Enabled" -Value 0
}

Invoke-Step "Disable consumer features policy" {
    Set-RegDword -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableThirdPartySuggestions" -Value 1
}

# 3. Disable Bing / web search in Start and Search
Write-Section "3. DISABLE WEB / BING SEARCH IN START"

Invoke-Step "Disable web results in Windows Search" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
}

# Windows Search / WSearch service is intentionally untouched.

# 4. Promotional notifications / Welcome Experience / setup suggestions
Write-Section "4. DISABLE PROMOTIONAL NOTIFICATIONS AND SETUP SUGGESTIONS"

Invoke-Step "Disable Windows Welcome Experience and tips" {
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

    Set-RegDword -Path $path -Name "SubscribedContent-310093Enabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-338389Enabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-353694Enabled" -Value 0
    Set-RegDword -Path $path -Name "SubscribedContent-353696Enabled" -Value 0
}

Invoke-Step "Disable Settings suggestions and setup prompts" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value 0
}

Invoke-Step "Disable tailored and cloud promotional experiences" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightOnActionCenter" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightOnSettings" -Value 1
    Set-RegDword -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightWindowsWelcomeExperience" -Value 1
}

Invoke-Step "Disable OneDrive sync suggestions in Explorer" {
    Set-RegDword -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value 0
}

Write-Section "APPLY CHANGES"

Invoke-Step "Refresh Group Policy" {
    & gpupdate.exe /force | Out-Null
}

Write-Host ""
Write-Host "Finished." -ForegroundColor Green
Write-Host "Only the requested four groups were modified." -ForegroundColor Gray
Write-Host "Windows Update, Delivery Optimization service, Windows Search service," -ForegroundColor Gray
Write-Host "Defender, firewall, Hyper-V, RDP, power settings and other services were NOT changed." -ForegroundColor Gray
Write-Host ""
Write-Host "A sign-out or restart is recommended for all Start/Search changes to take effect." -ForegroundColor Yellow
Write-Host ""
