$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & "$PSScriptRoot\moon.ps1" version --all
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & node.exe "$PSScriptRoot\verify-task7.mjs"
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
