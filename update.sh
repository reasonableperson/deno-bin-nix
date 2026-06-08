#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

current_version="$(jq -r '.version' release.json)"
release_json="$(curl -fsSL https://api.github.com/repos/denoland/deno/releases/latest)"
latest_tag="$(jq -r '.tag_name' <<< "$release_json")"
latest_version="${latest_tag#v}"

if [[ "$latest_version" == "$current_version" ]]; then
  echo "deno is already up to date at ${current_version}"
  exit 0
fi

echo "updating version ${current_version} -> ${latest_version}"

parse_asset() {
  jq -r --arg name "$1" '
    .assets[] | select(.name == $name) | {
      url: .browser_download_url,
      sha256: (.digest | sub("^sha256:"; ""))
    }' <<< "$release_json" | sed '2,$s/^/    /'
}

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
