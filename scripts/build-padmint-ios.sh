#!/usr/bin/env bash
# PadMint's iPhone/iPad build of EctoPad, from a fresh clone: the exact
# Metaforce workspace EctoPad is tested with, EctoPad's own app icon, the iOS
# device app and an IPA to sign with your own Apple ID. No game data is read:
# players import their own Metroid Prime (USA, Rev 2) disc image inside EctoPad.
#
#   scripts/build-padmint-ios.sh OUTPUT.ipa
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="${1:?usage: scripts/build-padmint-ios.sh OUTPUT.ipa}"
jobs="${ECTOPAD_BUILD_JOBS:-$(sysctl -n hw.ncpu)}"
cd "$root"

/bin/bash scripts/bootstrap-workspace.sh
bash scripts/sync-app-icon.sh
echo "EctoPad: configuring and building the iOS app"
(cd ref/metaforce && cmake --preset ios-default && cmake --build --preset ios-default --target metaforce -j "$jobs")
echo "EctoPad: packaging"
bash scripts/package-ios.sh "$root/ref/metaforce/build/ios-default/Binaries/Metaforce.app" "$output"

