#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

latest_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}\n' \
  https://github.com/denoland/deno/releases/latest)"
latest_tag="${latest_url##*/}"
latest_version="${latest_tag#v}"
current_version="$(sed -n 's|.*denoVersion = "\([^"]*\)".*|\1|p' flake.nix | head -n1)"

if [[ "$latest_version" == "$current_version" ]]; then
  echo "deno-bin is already up to date at ${current_version}"
  exit 0
fi

echo "syncing Deno version ${current_version} -> ${latest_version}"

x64_hash="$(nix store prefetch-file --json "https://github.com/denoland/deno/releases/download/${latest_tag}/deno-x86_64-unknown-linux-gnu.zip" | jq -r .hash)"
arm64_hash="$(nix store prefetch-file --json "https://github.com/denoland/deno/releases/download/${latest_tag}/deno-aarch64-unknown-linux-gnu.zip" | jq -r .hash)"

NEW_VERSION="$latest_version" X64_HASH="$x64_hash" ARM64_HASH="$arm64_hash" perl -0pi -e '
  my $new_version = $ENV{NEW_VERSION};
  my $x64_hash = $ENV{X64_HASH};
  my $arm64_hash = $ENV{ARM64_HASH};
  s/denoVersion = "[^"]*"/denoVersion = "$new_version"/;
  s/denoX64Hash = "[^"]*"/denoX64Hash = "$x64_hash"/;
  s/denoArm64Hash = "[^"]*"/denoArm64Hash = "$arm64_hash"/;
' flake.nix
