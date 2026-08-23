#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

repository_root=$(git rev-parse --show-toplevel)
source_lock="$repository_root/npins/sources.json"
projection_directory="$repository_root/bluebuild/recipes/spectrum/sources"
mode=${1:-write}

if [[ $mode != write && $mode != --check ]]; then
	printf 'usage: %s [--check]\n' "${0##*/}" >&2
	exit 2
fi

project() {
	local filter=$1
	local destination=$2

	if [[ $mode == --check ]]; then
		if ! cmp <(jq --sort-keys "$filter" "$source_lock") "$destination"; then
			printf '%s is stale; run just source-update\n' \
				"${destination#"$repository_root/"}" >&2
			return 1
		fi
		return
	fi

	local temporary
	temporary=$(mktemp "${destination}.XXXXXX")
	if ! jq --sort-keys "$filter" "$source_lock" >"$temporary"; then
		rm -f "$temporary"
		return 1
	fi
	mv "$temporary" "$destination"
}

project \
	'{pins: {python_astral: (.pins.python_astral | {hash, url, version})}}' \
	"$projection_directory/astral.json"
project \
	'{pins: {
	  ghostty: (.pins.ghostty | {revision}),
	  ghostty_archive: (.pins.ghostty_archive | {hash, url}),
	  ghostty_zig_x86_64_linux: (.pins.ghostty_zig_x86_64_linux | {hash, url})
	}}' \
	"$projection_directory/ghostty.json"
project \
	'{pins: {
	  kanata_homebrew_archive: (.pins.kanata_homebrew_archive | {hash, url})
	}}' \
	"$projection_directory/kanata.json"
