#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

latest_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}\n' \
  https://github.com/denoland/deno/releases/latest)"
latest_version="${latest_url##*/}"
current_version="$(sed -n 's|.*releases/download/\(v[^/]*\)/.*|\1|p' flake.nix | head -n1)"

if [[ "$latest_version" == "$current_version" && -f flake.lock ]]; then
  echo "deno-bin is already up to date at ${current_version}"
  exit 0
fi

echo "syncing Deno version ${current_version} -> ${latest_version}"

OLD_TAG="$current_version" NEW_TAG="$latest_version" perl -0pi -e '
  my $old_tag = $ENV{OLD_TAG};
  my $new_tag = $ENV{NEW_TAG};
  my $old_version = $old_tag;
  my $new_version = $new_tag;
  $old_version =~ s/^v//;
  $new_version =~ s/^v//;
  s/\Q$old_tag\E/$new_tag/g;
  s/version = "\Q$old_version\E"/version = "$new_version"/g;
' flake.nix

nix flake update --flake "path:$PWD" deno-x86_64-linux deno-aarch64-linux
