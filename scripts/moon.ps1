$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskMoonHome = Join-Path $taskRoot '.tools\moon'
$taskNodeHome = Join-Path $taskRoot '.tools\node-v22.23.3-win-x64'
if (Test-Path -LiteralPath (Join-Path $taskMoonHome 'bin\moon.exe')) {
    $env:MOON_HOME = $taskMoonHome
    $env:PATH = "$taskMoonHome\bin;$env:PATH"
}
if (Test-Path -LiteralPath (Join-Path $taskNodeHome 'node.exe')) {
    $env:PATH = "$taskNodeHome;$env:PATH"
}
& moon.exe @args
exit $LASTEXITCODE
