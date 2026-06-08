#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

release_json="$(curl -fsSL https://api.github.com/repos/denoland/deno/releases/latest)"
latest_tag="$(jq -r '.tag_name' <<< "$release_json")"
latest_version="${latest_tag#v}"
current_version="$(jq -r '.version' assets.json)"

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

if [[ "$latest_version" == "$current_version" ]]; then
  echo "deno-bin is already up to date at ${current_version}"
  exit 0
fi

echo "syncing Deno version ${current_version} -> ${latest_version}"

jq \
  --arg version "$latest_version" \
  --arg x64_hash "$(asset_hash deno-x86_64-unknown-linux-gnu.zip)" \
  --arg linux_arm64_hash "$(asset_hash deno-aarch64-unknown-linux-gnu.zip)" \
  --arg darwin_arm64_hash "$(asset_hash deno-aarch64-apple-darwin.zip)" \
  '.version = $version
  | .assets["x86_64-linux"].hash = $x64_hash
  | .assets["aarch64-linux"].hash = $linux_arm64_hash
  | .assets["aarch64-darwin"].hash = $darwin_arm64_hash' \
  assets.json > assets.json.tmp

mv assets.json.tmp assets.json
