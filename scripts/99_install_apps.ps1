# install_apps.ps1
# Executes every .exe found in the "apps" folder, one at a time.
# Optional arguments and accepted exit codes can be configured per executable.

$ErrorActionPreference = 'Stop'

# apps folder is expected next to the "scripts" folder:
# root\
#   execute_scripts.cmd
#   scripts\
#       install_apps.ps1
#   apps\
#       app1.exe
#       app2.exe

$RootDir = Split-Path -Parent $PSScriptRoot
$AppsDir = Join-Path $RootDir 'apps'

# Optional arguments per executable.
# Executables not listed here will run WITHOUT arguments.
#Firefox Setup 140.17.0esr.msi
#msiexec.exe /i "FirefoxESR.msi" /qb! /norestart
$AppArguments = @{
    'vcredist_runtime_pack.exe' = @('-s')
	'msiexec.exe' = @('/i', 'FirefoxESR_140.17.0.msi', 'qb!', '/norestart')
    # '7zip.exe' = @('/S')
    # 'another_app.exe' = @('/quiet', '/norestart')
}

# Optional accepted exit codes per executable.
# Executables not listed here accept only exit code 0.
$SuccessCodes = @{
    # 'Visual C++ runtime install pack.exe' = @(0, 1001)
    # 'another_app.exe' = @(0, 3010, 1641)
}

if (-not (Test-Path -LiteralPath $AppsDir -PathType Container)) {
    Write-Host "[ERROR] Apps folder not found: $AppsDir" -ForegroundColor Red
    exit 1
}

$Executables = Get-ChildItem -LiteralPath $AppsDir -Filter '*.exe' -File | Sort-Object Name

if (-not $Executables) {
    Write-Host "[WARNING] No executable files were found in: $AppsDir" -ForegroundColor Yellow
    exit 0
}

$OkCount = 0
$ErrorCount = 0

foreach ($Exe in $Executables) {
    Write-Host ''
    Write-Host '============================================================'
    Write-Host "Executing: $($Exe.Name)"
    Write-Host '============================================================'

    $Arguments = @()
    if ($AppArguments.ContainsKey($Exe.Name)) {
        $Arguments = @($AppArguments[$Exe.Name])
    }

    $AcceptedCodes = @(0)
    if ($SuccessCodes.ContainsKey($Exe.Name)) {
        $AcceptedCodes = @($SuccessCodes[$Exe.Name])
    }

    try {
        # Native PowerShell invocation.
        # It runs the executable directly and waits until it returns.
        if ($Arguments.Count -gt 0) {
            & $Exe.FullName @Arguments
        }
        else {
            & $Exe.FullName
        }

        $ExitCode = $LASTEXITCODE

        # Some native programs may not set LASTEXITCODE. Treat that as success
        # only when PowerShell itself reports successful invocation.
        if ($null -eq $ExitCode) {
            if ($?) {
                $ExitCode = 0
            }
            else {
                $ExitCode = 1
            }
        }

        if ($AcceptedCodes -contains $ExitCode) {
            Write-Host "[OK] $($Exe.Name) returned exit code $ExitCode." -ForegroundColor Green
            $OkCount++
        }
        else {
            Write-Host "[ERROR] $($Exe.Name) returned exit code $ExitCode." -ForegroundColor Red
            $ErrorCount++
        }
    }
    catch {
        Write-Host "[ERROR] Failed to execute $($Exe.Name): $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ''
Write-Host '============================================================'
Write-Host 'Applications execution finished'
Write-Host "Success: $OkCount"
Write-Host "Errors : $ErrorCount"
Write-Host '============================================================'

if ($ErrorCount -gt 0) {
    exit 1
}

exit 0
