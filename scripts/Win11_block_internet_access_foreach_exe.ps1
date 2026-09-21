# Finds configured executables recursively and creates outbound Windows Firewall block rules for each executable found.

$executables = @(
    @{ path = "$env:ProgramFiles\Microsoft Office"; exeName = "WINWORD.EXE" },
    @{ path = "$env:ProgramFiles\Microsoft Office"; exeName = "EXCEL.EXE" },
    @{ path = "$env:ProgramFiles\Microsoft Office"; exeName = "POWERPNT.EXE" },
	@{ path = "$env:ProgramFiles\Microsoft Office"; exeName = "MSACCESS.EXE" },
	@{ path = "$env:ProgramFiles\Foxit Software\Foxit PDF Editor"; exeName = "FoxitPDFEditor.exe" }	
)

foreach ($item in $executables) {
    if (-not (Test-Path -LiteralPath $item.path)) {
        Write-Host "Path not found: $($item.path)" -ForegroundColor DarkYellow
		Write-Host ""
        continue
    }

    $files = Get-ChildItem -Path $item.path -Filter $item.exeName -File -Recurse -ErrorAction SilentlyContinue

    if (-not $files) {
        Write-Host "Executable not found: $($item.exeName) under $($item.path)" -ForegroundColor DarkYellow
		Write-Host ""
        continue
    }

    foreach ($file in $files) {
        $exePath = $file.FullName
        $ruleName = "Block Internet - $($file.Name)"

        Write-Host "Found: $exePath" -ForegroundColor Yellow

        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

        if ($null -eq $existingRule) {
            New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Program $exePath -Action Block -Profile Any -Enabled True | Out-Null
            Write-Host "Blocked: $exePath" -ForegroundColor Green
        }
        else {
            Write-Host "Rule already exists: $exePath" -ForegroundColor Cyan
        }
		
		Write-Host ""
    }
}

exit 0
