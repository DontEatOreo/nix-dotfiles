#!/usr/bin/bash
# shellcheck shell=bash

set -euo pipefail

: "${SOURCE_LOCK:?}"
: "${SOURCE_PIN:?}"
: "${REVISION_PIN:?}"
: "${ZIG_PIN:?}"
: "${PATCHES_LOCK:?}"
: "${PATCH_STACK:?}"
: "${PREFIX:?}"
: "${VERSION_PREFIX:?}"
: "${ARTIFACT:?}"
: "${BUILD_ARGUMENTS:?}"

read -r -a build_arguments <<<"$BUILD_ARGUMENTS"
source_url=$(jq -er --arg pin "$SOURCE_PIN" '.pins[$pin].url' "$SOURCE_LOCK")
source_hash=$(jq -er --arg pin "$SOURCE_PIN" '.pins[$pin].hash' "$SOURCE_LOCK")
zig_url=$(jq -er --arg pin "$ZIG_PIN" '.pins[$pin].url' "$SOURCE_LOCK")
zig_hash=$(jq -er --arg pin "$ZIG_PIN" '.pins[$pin].hash' "$SOURCE_LOCK")
revision=$(jq -er --arg pin "$REVISION_PIN" '.pins[$pin].revision' "$SOURCE_LOCK")
patches_repository=$(jq -er '.repository' "$PATCHES_LOCK")
patches_revision=$(jq -er '.revision' "$PATCHES_LOCK")

verify_sri() {
	local path=$1
	local expected=$2
	local actual
	actual="sha256-$(openssl dgst -sha256 -binary "$path" | openssl base64 -A)"
	if [[ $actual != "$expected" ]]; then
		printf 'checksum mismatch for %s\nexpected: %s\nactual:   %s\n' \
			"$path" "$expected" "$actual" >&2
		return 1
	fi
}

mkdir -p /build/source /build/zig "$PREFIX"
curl -fLsS --retry 5 "$source_url" -o /build/ghostty.tar.gz
curl -fLsS --retry 5 "$zig_url" -o /build/zig.tar.xz
verify_sri /build/ghostty.tar.gz "$source_hash"
verify_sri /build/zig.tar.xz "$zig_hash"

tar -xzf /build/ghostty.tar.gz --strip-components=1 -C /build/source
tar -xJf /build/zig.tar.xz --strip-components=1 -C /build/zig

git init -q /build/patches
git -C /build/patches remote add origin "$patches_repository"
git -C /build/patches fetch --depth=1 origin "$patches_revision"
git -C /build/patches checkout --detach --quiet FETCH_HEAD
patches="/build/patches/stacks/$PATCH_STACK/patches"
test -s "$patches/series"

while IFS= read -r patch_name; do
	git -C /build/source apply "$patches/$patch_name"
done <"$patches/series"

version="$VERSION_PREFIX.${revision:0:7}"
(
	cd /build/source
	PATH="/build/zig:$PATH" ZIG_GLOBAL_CACHE_DIR=/build/zig-cache \
		/build/zig/zig build \
		-p "$PREFIX" \
		"${build_arguments[@]}" \
		"-Dversion-string=$version"
)

test -x "$ARTIFACT"
find "$PREFIX" -type f -name '*.la' -delete
