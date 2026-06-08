#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

release_json="$(curl -fsSL https://api.github.com/repos/denoland/deno/releases/latest)"
latest_tag="$(jq -r '.tag_name' <<< "$release_json")"
latest_version="${latest_tag#v}"
current_version="$(sed -n 's|.*denoVersion = "\([^"]*\)".*|\1|p' flake.nix | head -n1)"

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

x64_hash="$(asset_hash deno-x86_64-unknown-linux-gnu.zip)"
linux_arm64_hash="$(asset_hash deno-aarch64-unknown-linux-gnu.zip)"
darwin_arm64_hash="$(asset_hash deno-aarch64-apple-darwin.zip)"

NEW_VERSION="$latest_version" X64_HASH="$x64_hash" LINUX_ARM64_HASH="$linux_arm64_hash" DARWIN_ARM64_HASH="$darwin_arm64_hash" perl -0pi -e '
  my $new_version = $ENV{NEW_VERSION};
  my $x64_hash = $ENV{X64_HASH};
  my $linux_arm64_hash = $ENV{LINUX_ARM64_HASH};
  my $darwin_arm64_hash = $ENV{DARWIN_ARM64_HASH};
  s/denoVersion = "[^"]*"/denoVersion = "$new_version"/;
  s/(x86_64-linux = \{\s+hash = ")[^"]*(";)/$1$x64_hash$2/s;
  s/(aarch64-linux = \{\s+hash = ")[^"]*(";)/$1$linux_arm64_hash$2/s;
  s/(aarch64-darwin = \{\s+hash = ")[^"]*(";)/$1$darwin_arm64_hash$2/s;
' flake.nix
