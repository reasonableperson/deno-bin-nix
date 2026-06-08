#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

release_json="$(curl -fsSL https://api.github.com/repos/denoland/deno/releases/latest)"
latest_tag="$(jq -r '.tag_name' <<< "$release_json")"
latest_version="${latest_tag#v}"
current_version="$(jq -r '.version' metadata.json)"

asset_hash() {
  local asset_name="$1"
  local digest
  digest="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .digest' <<< "$release_json")"

  if [[ -z "$digest" || "$digest" == "null" ]]; then
    echo "missing digest for ${asset_name}" >&2
    exit 1
  fi

  nix hash convert --from hex --to nix32 "${digest#sha256:}"
}

asset_url() {
  local asset_name="$1"
  local url
  url="$(jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .browser_download_url' <<< "$release_json")"

  if [[ -z "$url" || "$url" == "null" ]]; then
    echo "missing url for ${asset_name}" >&2
    exit 1
  fi

  printf '%s\n' "$url"
}

if [[ "$latest_version" == "$current_version" ]]; then
  echo "deno-bin is already up to date at ${current_version}"
  exit 0
fi

echo "syncing Deno version ${current_version} -> ${latest_version}"

cat > metadata.json.tmp <<EOF
{
  "version": "${latest_version}",
  "assets": {
    "x86_64-linux": {
      "url": "$(asset_url deno-x86_64-unknown-linux-gnu.zip)",
      "hash": "$(asset_hash deno-x86_64-unknown-linux-gnu.zip)"
    },
    "aarch64-linux": {
      "url": "$(asset_url deno-aarch64-unknown-linux-gnu.zip)",
      "hash": "$(asset_hash deno-aarch64-unknown-linux-gnu.zip)"
    },
    "aarch64-darwin": {
      "url": "$(asset_url deno-aarch64-apple-darwin.zip)",
      "hash": "$(asset_hash deno-aarch64-apple-darwin.zip)"
    }
  }
}
EOF

mv metadata.json.tmp metadata.json
