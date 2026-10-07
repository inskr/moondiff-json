# Installs only into this project's .tools; no user PATH or policy changes.
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskTools = Join-Path $taskRoot '.tools'
$taskDownloads = Join-Path $taskTools 'downloads'
New-Item -ItemType Directory -Path $taskDownloads -Force | Out-Null

function Get-PinnedArchive([string]$Url, [string]$File, [string]$Sha256) {
    $taskDestination = Join-Path $taskDownloads $File
    if (!(Test-Path -LiteralPath $taskDestination)) {
        Invoke-WebRequest -Uri $Url -OutFile $taskDestination
    }
    $taskActual = (Get-FileHash -LiteralPath $taskDestination -Algorithm SHA256).Hash.ToLower()
    if ($taskActual -ne $Sha256) { throw "SHA256 mismatch: $File. Do not use this archive." }
    return $taskDestination
}

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'This verified setup supports Windows x64 only.' }
$taskMoonZip = Get-PinnedArchive `
    'https://cli.moonbitlang.com/binaries/0.10.14%2B7d59c7ec9/moonbit-windows-x86_64.zip' `
    'moonbit.zip' 'faae225a8287d0ce69e44b5b3f754af988e97f4446056d8f32ceb3ddb998fce7'
$taskCoreZip = Get-PinnedArchive `
    'https://cli.moonbitlang.com/cores/core-0.10.14%2B7d59c7ec9.zip' `
    'core.zip' '63e5b99991ac8fd49556b1e17bdcbdc662d797000250dd11ef090f38a2175e84'
$taskNodeZip = Get-PinnedArchive `
    'https://nodejs.org/dist/v22.23.3/node-v22.23.3-win-x64.zip' `
    'node22.zip' '2b0ff57b049cda1bbcea2240eec20467018713c1efe1f7360c2681859b90ed71'
Expand-Archive -LiteralPath $taskMoonZip -DestinationPath (Join-Path $taskTools 'moon') -Force
Expand-Archive -LiteralPath $taskCoreZip -DestinationPath (Join-Path $taskTools 'moon\lib') -Force
Expand-Archive -LiteralPath $taskNodeZip -DestinationPath $taskTools -Force
$env:MOON_HOME = Join-Path $taskTools 'moon'
$env:PATH = "$taskTools\node-v22.23.3-win-x64;$env:MOON_HOME\bin;$env:PATH"
Push-Location (Join-Path $env:MOON_HOME 'lib\core')
try {
    & moon.exe bundle --target js --warn-list -a
    if ($LASTEXITCODE -ne 0) { throw 'Core JS bundle failed' }
} finally {
    Pop-Location
}
& moon.exe version --all
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& node.exe --version
