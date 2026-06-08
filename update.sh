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

x64_hash="$(nix-prefetch-url --unpack "https://github.com/denoland/deno/releases/download/${latest_tag}/deno-x86_64-unknown-linux-gnu.zip")"
linux_arm64_hash="$(nix-prefetch-url --unpack "https://github.com/denoland/deno/releases/download/${latest_tag}/deno-aarch64-unknown-linux-gnu.zip")"
darwin_arm64_hash="$(nix-prefetch-url --unpack "https://github.com/denoland/deno/releases/download/${latest_tag}/deno-aarch64-apple-darwin.zip")"

NEW_VERSION="$latest_version" X64_HASH="$x64_hash" LINUX_ARM64_HASH="$linux_arm64_hash" DARWIN_ARM64_HASH="$darwin_arm64_hash" perl -0pi -e '
  my $new_version = $ENV{NEW_VERSION};
  my $x64_hash = $ENV{X64_HASH};
  my $linux_arm64_hash = $ENV{LINUX_ARM64_HASH};
  my $darwin_arm64_hash = $ENV{DARWIN_ARM64_HASH};
  s/denoVersion = "[^"]*"/denoVersion = "$new_version"/;
  s/denoX64Hash = "[^"]*"/denoX64Hash = "$x64_hash"/;
  s/denoLinuxArm64Hash = "[^"]*"/denoLinuxArm64Hash = "$linux_arm64_hash"/;
  s/denoDarwinArm64Hash = "[^"]*"/denoDarwinArm64Hash = "$darwin_arm64_hash"/;
' flake.nix
