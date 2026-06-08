#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

release_json="$(curl -fsSL https://api.github.com/repos/denoland/deno/releases/latest)"
latest_tag="$(jq -r '.tag_name' <<< "$release_json")"
latest_version="${latest_tag#v}"
current_version="$(jq -r '.version' release.json)"

parse_asset() {
  jq -r --arg name "$1" '
    .assets[]
    | select(.name == $name)
    | {
        url: .browser_download_url,
        sha256: (.digest | sub("^sha256:"; ""))
      }
  ' <<< "$release_json"
}

if [[ "$latest_version" == "$current_version" ]]; then
  echo "deno-bin is already up to date at ${current_version}"
  exit 0
fi

echo "syncing Deno version ${current_version} -> ${latest_version}"

cat > release.json <<EOF
{
  "version": "${latest_version}",
  "assets": {
    "x86_64-linux": $(parse_asset deno-x86_64-unknown-linux-gnu.zip),
    "aarch64-linux": $(parse_asset deno-aarch64-unknown-linux-gnu.zip),
    "aarch64-darwin": $(parse_asset deno-aarch64-apple-darwin.zip)
  }
}
EOF
