# Build ~/.memwal/credentials.json from 1Password "walrus memory" item (Claude vault).
$ErrorActionPreference = 'Stop'

$envScript = Join-Path $env:USERPROFILE '.config\op\env.ps1'
if (-not (Test-Path $envScript)) {
    Write-Error "Missing 1Password env script: $envScript"
}

. $envScript

$item = op item get 'walrus memory' --vault Claude --format json | ConvertFrom-Json
$fields = @{}
foreach ($f in $item.fields) {
    if ($f.label -and $f.value) {
        $fields[$f.label.Trim()] = $f.value
    }
}

$required = @('MEMWAL_PRIVATE_KEY', 'Delegate public key', 'MEMWAL_ACCOUNT_ID', 'MEMWAL_SERVER_URL')
foreach ($name in $required) {
    if (-not $fields.ContainsKey($name)) {
        throw "Missing required 1Password field: $name"
    }
}

$memwalPkg = Get-ChildItem "$env:LOCALAPPDATA\npm-cache\_npx" -Recurse -Directory -Filter 'memwal-mcp' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like '*@mysten-incubation*' } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $memwalPkg) {
    npx -y @mysten-incubation/memwal-mcp --help | Out-Null
    $memwalPkg = Get-ChildItem "$env:LOCALAPPDATA\npm-cache\_npx" -Recurse -Directory -Filter 'memwal-mcp' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like '*@mysten-incubation*' } |
        Select-Object -First 1 -ExpandProperty FullName
}

$cryptoJs = Join-Path $memwalPkg 'dist\crypto.js'
$deriveScript = @"
import { deriveSuiAddress, hexToBytes } from 'file:///$($cryptoJs -replace '\\','/')';
const pub = hexToBytes(process.argv[1]);
process.stdout.write(deriveSuiAddress(pub));
"@
$deriveFile = Join-Path $env:TEMP 'memwal-derive.mjs'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($deriveFile, $deriveScript, $utf8NoBom)
$delegateAddress = node $deriveFile $fields['Delegate public key']

$packageId = '0xcee7a6fd8de52ce645c38332bde23d4a30fd9426bc4681409733dd50958a24c6'

$creds = [ordered]@{
    delegatePrivateKey   = $fields['MEMWAL_PRIVATE_KEY']
    delegatePublicKeyHex = $fields['Delegate public key']
    delegateAddress      = $delegateAddress
    walletAddress        = $delegateAddress
    accountId            = $fields['MEMWAL_ACCOUNT_ID']
    packageId            = $packageId
    relayerUrl           = $fields['MEMWAL_SERVER_URL'].TrimEnd('/')
    label                = 'Grok MCP'
    createdAt            = (Get-Date).ToUniversalTime().ToString('o')
    version              = 1
}

$dir = Join-Path $env:USERPROFILE '.memwal'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$path = Join-Path $dir 'credentials.json'
$json = $creds | ConvertTo-Json -Depth 3
[System.IO.File]::WriteAllText($path, $json, $utf8NoBom)
Write-Output "Wrote $path"