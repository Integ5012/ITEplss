# Creates deploy-backend.zip with backend/ contents at zip root (for Azure App Service Oryx).
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $repoRoot "backend"
$outZip = Join-Path $repoRoot "deploy-backend.zip"

if (-not (Test-Path $backend)) {
    Write-Error "backend folder not found at $backend"
}

if (Test-Path $outZip) {
    Remove-Item $outZip -Force
}

Push-Location $backend
try {
    Compress-Archive -Path * -DestinationPath $outZip -Force
    Write-Host "Created $outZip"
}
finally {
    Pop-Location
}
