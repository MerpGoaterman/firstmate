#!/usr/bin/env bash
# Build ~/.memwal/credentials.json from 1Password "walrus memory" item (Claude vault).
set -eu

command -v op >/dev/null 2>&1 || {
  echo "error: 1Password CLI (op) not found" >&2
  exit 1
}
command -v node >/dev/null 2>&1 || {
  echo "error: node not found" >&2
  exit 1
}

item_json=$(op item get 'walrus memory' --vault Claude --format json)

read_field() {
  local label=$1
  printf '%s\n' "$item_json" | node -e '
    const label = process.argv[1];
    const item = JSON.parse(require("fs").readFileSync(0, "utf8"));
    const field = (item.fields || []).find((f) => (f.label || "").trim() === label);
    if (!field || !field.value) process.exit(2);
    process.stdout.write(String(field.value));
  ' "$label"
}

private_key=$(read_field 'MEMWAL_PRIVATE_KEY')
public_key=$(read_field 'Delegate public key')
account_id=$(read_field 'MEMWAL_ACCOUNT_ID')
relayer_url=$(read_field 'MEMWAL_SERVER_URL')

npx -y @mysten-incubation/memwal-mcp --help >/dev/null 2>&1 || true
memwal_pkg=$(find "${TMPDIR:-/tmp}" "$HOME/.npm" "$HOME/Library/Caches" -path '*@mysten-incubation*/node_modules/*/memwal-mcp' -type d 2>/dev/null | head -n 1 || true)
if [ -z "$memwal_pkg" ]; then
  memwal_pkg=$(find "$HOME" -path '*node_modules/@mysten-incubation/memwal-mcp/dist/crypto.js' 2>/dev/null | head -n 1 || true)
  memwal_pkg=${memwal_pkg%/dist/crypto.js}
fi
[ -n "$memwal_pkg" ] && [ -f "$memwal_pkg/dist/crypto.js" ] || {
  echo "error: could not locate memwal-mcp crypto.js after npx prefetch" >&2
  exit 1
}

delegate_address=$(node -e '
  import { deriveSuiAddress, hexToBytes } from "file://" + process.argv[1];
  process.stdout.write(deriveSuiAddress(hexToBytes(process.argv[2])));
' "$memwal_pkg/dist/crypto.js" "$public_key")

package_id='0xcee7a6fd8de52ce645c38332bde23d4a30fd9426bc4681409733dd50958a24c6'
relayer_url=${relayer_url%/}
created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$HOME/.memwal"
node -e '
  const fs = require("fs");
  const path = require("path");
  const out = path.join(process.env.HOME, ".memwal", "credentials.json");
  const creds = {
    delegatePrivateKey: process.argv[1],
    delegatePublicKeyHex: process.argv[2],
    delegateAddress: process.argv[3],
    walletAddress: process.argv[3],
    accountId: process.argv[4],
    packageId: process.argv[5],
    relayerUrl: process.argv[6],
    label: "Grok MCP",
    createdAt: process.argv[7],
    version: 1,
  };
  fs.writeFileSync(out, JSON.stringify(creds, null, 2) + "\n");
  process.stdout.write("Wrote " + out + "\n");
' "$private_key" "$public_key" "$delegate_address" "$account_id" "$package_id" "$relayer_url" "$created_at"