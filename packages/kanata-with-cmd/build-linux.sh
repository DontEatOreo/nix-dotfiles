#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

source_lock=${SOURCE_LOCK:?SOURCE_LOCK must point to the projected source lock}
source_pin=${SOURCE_PIN:-kanata_homebrew_archive}
patches_lock=${PATCHES_LOCK:?PATCHES_LOCK must point to the shared repository lock}
patch_stack=${PATCH_STACK:-kanata}
prefix=${PREFIX:-/out/usr}
source_directory=${SOURCE_DIRECTORY:-/build/kanata-source}

archive=$(mktemp)
trap 'rm -f -- "$archive"' EXIT

python3 - "$source_lock" "$source_pin" "$archive" <<'PYTHON'
import base64
import hashlib
import json
import sys
import urllib.request
from pathlib import Path

source_lock, source_pin, archive = sys.argv[1:]
pin = json.loads(Path(source_lock).read_text())["pins"][source_pin]
urllib.request.urlretrieve(pin["url"], archive)

algorithm, encoded_digest = pin["hash"].split("-", maxsplit=1)
if algorithm != "sha256":
    raise ValueError(f"unsupported Kanata archive hash: {algorithm}")
expected_digest = base64.b64decode(encoded_digest, validate=True)
actual_digest = hashlib.sha256(Path(archive).read_bytes()).digest()
if actual_digest != expected_digest:
    raise ValueError("Kanata source archive checksum mismatch")
PYTHON

install -d -m 0755 "$source_directory"
tar -xf "$archive" --strip-components=1 -C "$source_directory"

patches_repository=$(jq -er '.repository' "$patches_lock")
patches_revision=$(jq -er '.revision' "$patches_lock")
git init -q /build/patches
git -C /build/patches remote add origin "$patches_repository"
git -C /build/patches fetch --depth=1 origin "$patches_revision"
git -C /build/patches checkout --detach --quiet FETCH_HEAD
patches="/build/patches/stacks/$patch_stack/patches"
test -s "$patches/series"

while IFS= read -r patch_name || [[ -n $patch_name ]]; do
	[[ -n $patch_name ]] || continue
	git -C "$source_directory" apply "$patches/$patch_name"
done <"$patches/series"

cargo build \
	--manifest-path "$source_directory/Cargo.toml" \
	--locked \
	--release \
	--features cmd \
	--bin kanata
install -D -m 0755 "$source_directory/target/release/kanata" "$prefix/bin/kanata"
"$prefix/bin/kanata" --version
