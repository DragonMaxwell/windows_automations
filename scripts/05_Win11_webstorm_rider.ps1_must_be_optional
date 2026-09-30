# Install Jetbrains Webstorm
# Install Jetbrains Rider

# WebStorm
if (-not (winget list --id JetBrains.WebStorm --exact 2>$null | Select-String "JetBrains.WebStorm")) {
    winget install --id JetBrains.WebStorm --exact --silent --accept-package-agreements --accept-source-agreements
}

# Rider
if (-not (winget list --id JetBrains.Rider --exact 2>$null | Select-String "JetBrains.Rider")) {
    winget install --id JetBrains.Rider --exact --silent --accept-package-agreements --accept-source-agreements
}