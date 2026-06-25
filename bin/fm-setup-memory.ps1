# Windows one-liner entrypoint for fm-setup-memory.sh
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$bash = $null
foreach ($candidate in @(
    'C:\Program Files\Git\bin\bash.exe',
    'C:\msys64\usr\bin\bash.exe'
)) {
    if (Test-Path $candidate) {
        $bash = $candidate
        break
    }
}

if (-not $bash) {
    throw 'bash not found. Install Git for Windows or MSYS2, then re-run bin/fm-setup-memory.ps1'
}

& $bash (Join-Path $here 'fm-setup-memory.sh') @args