#!/bin/bash
# Recreate EctoPad's ignored ref/metaforce workspace from a fresh clone.
#
# Metaforce and every component are fetched at the commits EctoPad was built
# and tested with, then patches/workspace/<component>.patch restores EctoPad's
# changes exactly (captured from the maintained workspace). Git checks each
# commit by its hash, so mirrors yield identical sources. Two upstream
# repositories (AxioDL/kabufuda and AxioDL/amuse) are no longer on GitHub;
# their pinned commits are fetched from public forks that still carry them.
#
#   scripts/bootstrap-workspace.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
ref="$root/ref/metaforce"
patches="$root/patches/workspace"
marker="$ref/.ectopad-workspace"
want="$(cat "$patches"/*.patch | shasum -a 256 | cut -d' ' -f1)"

if [ -f "$marker" ] && [ "$(cat "$marker")" = "$want" ]; then
  echo "EctoPad workspace is ready at $ref"
  exit 0
fi
if [ -e "$ref" ]; then
  echo "ref/metaforce exists but was not made by this script for these patches; move it aside first." >&2
  exit 1
fi

fetch() { # directory url commit
  git init -q "$1"
  git -C "$1" remote add origin "$2"
  git -C "$1" fetch -q --filter=blob:none origin "$3"
  git -C "$1" checkout -q --detach "$3"
}

echo "EctoPad: fetching Metaforce and its components"
fetch "$ref" https://github.com/AxioDL/metaforce.git 621ee0fed3fdd5fccbbdadbce33343f29dce071c
git -C "$ref" config submodule.extern/kabufuda.url https://github.com/cualquiercosa327/kabufuda.git
git -C "$ref" submodule update -q --init --recursive

ext="$ref/extern"
fetch "$ext/amuse" https://github.com/derselbst/amuse.git ad9bc96af472dae03fde215163446bdec80be67f
fetch "$ext/athena" https://github.com/encounter/athena.git 6adba82abd8b7f48e6eca9f74361d0c605bc9ec8
git -C "$ext/athena" submodule update -q --init --recursive
fetch "$ext/logvisor" https://github.com/AxioDL/logvisor.git 208a8c1f84f9968695d712b8e5625c0dc85edbae
fetch "$ext/lzokay" https://github.com/AxioDL/lzokay.git db2df1fcbebc2ed06c10f727f72567d40f06a2be
fetch "$ext/soxr" https://github.com/chirlu/soxr.git 945b592b70470e29f917f4de89b4281fbbd540c0

echo "EctoPad: applying the EctoPad changes"
apply() { # directory patch
  if [ -s "$patches/$2.patch" ]; then
    git -C "$1" apply --whitespace=nowarn "$patches/$2.patch"
  fi
}
apply "$ref" metaforce
for component in aurora kabufuda nod amuse athena logvisor lzokay soxr; do
  apply "$ext/$component" "$component"
done

echo "$want" > "$marker"
echo "EctoPad workspace is ready at $ref"

