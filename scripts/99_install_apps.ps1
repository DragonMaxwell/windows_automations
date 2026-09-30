# 99_install_apps.ps1
# Installs applications in exactly the order declared below.
# The next installer starts only after the current installer has finished or failed.

$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$AppsDir = Join-Path $RootDir 'apps'

if (-not (Test-Path -LiteralPath $AppsDir -PathType Container)) {
    Write-Host "[ERROR] Apps folder not found: $AppsDir" -ForegroundColor Red
    Write-Host ''
    Write-Host 'Closing in 10 seconds...'
    & "$env:SystemRoot\System32\timeout.exe" /t 10 /nobreak
    exit 1
}

$Is64BitWindows = [Environment]::Is64BitOperatingSystem

# Installation order is the declaration order below.
# Parameters for Visual C++ runtimes match the old install.cmd that was already working.
$Apps = @(
    @{
        File         = 'FirefoxESR_140.17.0.msi'
        Type         = 'MSI'
        Architecture = 'Any'
        Arguments    = '/passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2005_x86.exe'
        Type         = 'EXE'
        Architecture = 'x86'
        Arguments    = '/q'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2005_x64.exe'
        Type         = 'EXE'
        Architecture = 'x64'
        Arguments    = '/q'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2008_x86.exe'
        Type         = 'EXE'
        Architecture = 'x86'
        Arguments    = '/q'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2008_x64.exe'
        Type         = 'EXE'
        Architecture = 'x64'
        Arguments    = '/q'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2010_x86.exe'
        Type         = 'EXE'
        Architecture = 'x86'
        Arguments    = '/passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2010_x64.exe'
        Type         = 'EXE'
        Architecture = 'x64'
        Arguments    = '/passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2012_x86.exe'
        Type         = 'EXE'
        Architecture = 'x86'
        Arguments    = '/passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2012_x64.exe'
        Type         = 'EXE'
        Architecture = 'x64'
        Arguments    = '/passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2013_x86.exe'
        Type         = 'EXE'
        Architecture = 'x86'
        Arguments    = '/install /passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2013_x64.exe'
        Type         = 'EXE'
        Architecture = 'x64'
        Arguments    = '/install /passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2015-2026_x86.exe'
        Type         = 'EXE'
        Architecture = 'x86'
        Arguments    = '/install /passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }

    @{
        File         = 'vcredist2015-2026_x64.exe'
        Type         = 'EXE'
        Architecture = 'x64'
        Arguments    = '/install /passive /norestart'
        SuccessCodes = @(0, 1641, 3010)
    }
)

$SuccessCount = 0
$ErrorCount = 0
$SkippedCount = 0

foreach ($App in $Apps) {
    if ($App.Architecture -eq 'x64' -and -not $Is64BitWindows) {
        Write-Host "[SKIP] $($App.File) requires 64-bit Windows." -ForegroundColor DarkGray
        $SkippedCount++
        continue
    }

    $InstallerPath = Join-Path $AppsDir $App.File

    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
        Write-Host "[SKIP] $($App.File) not found." -ForegroundColor DarkGray
        $SkippedCount++
        continue
    }

    Write-Host ''
    Write-Host '============================================================'
    Write-Host "Installing: $($App.File)"
    Write-Host '============================================================'

    try {
        if ($App.Type -eq 'MSI') {
            # Keep the MSI path explicitly quoted so paths with spaces work correctly.
            $MsiArguments = '/i "' + $InstallerPath + '" ' + $App.Arguments

            $Process = Start-Process `
                -FilePath "$env:SystemRoot\System32\msiexec.exe" `
                -ArgumentList $MsiArguments `
                -Wait `
                -PassThru
        }
        elseif ($App.Type -eq 'EXE') {
            $Process = Start-Process `
                -FilePath $InstallerPath `
                -ArgumentList $App.Arguments `
                -Wait `
                -PassThru
        }
        else {
            throw "Unsupported installer type: $($App.Type)"
        }

        $ExitCode = $Process.ExitCode

        if ($App.SuccessCodes -contains $ExitCode) {
            if ($ExitCode -in 1641, 3010) {
                Write-Host "[OK] $($App.File) completed. Restart required. Exit code: $ExitCode" -ForegroundColor Yellow
            }
            else {
                Write-Host "[OK] $($App.File) completed. Exit code: $ExitCode" -ForegroundColor Green
            }

            $SuccessCount++
        }
        else {
            Write-Host "[ERROR] $($App.File) returned exit code $ExitCode." -ForegroundColor Red
            $ErrorCount++
        }
    }
    catch {
        Write-Host "[ERROR] $($App.File): $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ''
Write-Host '============================================================'
Write-Host 'Application installation completed'
Write-Host "Success : $SuccessCount"
Write-Host "Errors  : $ErrorCount"
Write-Host "Skipped : $SkippedCount"
Write-Host '============================================================'
Write-Host ''
Write-Host 'Closing in 5 seconds...'

& "$env:SystemRoot\System32\timeout.exe" /t 5 /nobreak

if ($ErrorCount -gt 0) {
    exit 1
}

exit 0
