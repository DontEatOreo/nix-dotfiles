#!/usr/bin/env bash

set -euo pipefail

lock_file=${1:-npins/sources.json}

npins --lock-file "$lock_file" update

# Formulae need flat archive hashes, while Git/GitRelease pins store hashes of
# their unpacked Nix source trees. Refresh every paired *_archive URL after its
# source pin moves so Homebrew receives a stable, byte-level SHA-256.
while IFS=$'\t' read -r archive_name source_url archive_url; do
	[[ "$source_url" == "$archive_url" ]] && continue
	npins --lock-file "$lock_file" add url "$source_url" \
		--name "$archive_name" \
		--frozen
done < <(
	jq -r '
    .pins as $pins
    | $pins
    | to_entries[]
    | select(.key | endswith("_archive"))
    | (.key | rtrimstr("_archive")) as $source_name
    | select($pins[$source_name] != null)
    | [.key, $pins[$source_name].url, .value.url]
    | @tsv
  ' "$lock_file"
)

# Helium publishes its runnable Linux build as a release asset rather than the
# GitHub-generated source archive tracked by npins. Keep that frozen byte hash
# paired with the moving release pin as part of the same source update.
helium_version=$(jq -r '.pins.helium_linux.version // empty' "$lock_file")
if [[ -n $helium_version ]]; then
	helium_asset_url="https://github.com/imputnet/helium-linux/releases/download/${helium_version}/helium-${helium_version}-x86_64_linux.tar.xz"
	current_helium_asset_url=$(jq -r '.pins.helium_linux_binary.url // empty' "$lock_file")
	if [[ $helium_asset_url != "$current_helium_asset_url" ]]; then
		npins --lock-file "$lock_file" add url "$helium_asset_url" \
			--name helium_linux_binary \
			--frozen
	fi
fi
