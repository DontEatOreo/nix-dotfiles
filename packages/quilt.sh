#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=${script_dir%/packages}
quiltrc=$repo_root/dotfiles/dot_quiltrc
packages=(ghostty-patched jj-patched kanata-with-cmd)

usage() {
	printf '%s\n' \
		'Usage: packages/quilt.sh check [all|PACKAGE]' \
		'       packages/quilt.sh shell PACKAGE' \
		'' \
		'Packages: ghostty-patched, jj-patched, kanata-with-cmd'
}

die() {
	printf '%s\n' "$*" >&2
	exit 1
}

source_pin() {
	case $1 in
		ghostty-patched) printf '%s\n' ghostty ;;
		jj-patched) printf '%s\n' jj ;;
		kanata-with-cmd) printf '%s\n' kanata_homebrew ;;
		*) return 1 ;;
	esac
}

validate_series() {
	local patch_dir=$1
	local patch_name

	[[ -s $patch_dir/series ]] || die "Empty patch series: $patch_dir/series"
	while IFS= read -r patch_name; do
		[[ $patch_name =~ ^[A-Za-z0-9._-]+\.patch$ ]] ||
			die "Invalid patch series entry: $patch_name"
		[[ -f $patch_dir/$patch_name ]] ||
			die "Missing patch: $patch_dir/$patch_name"
	done <"$patch_dir/series"
}

prepare_source() {
	local package=$1
	local workspace=$2
	local pin source_path

	pin=$(source_pin "$package")
	source_path=$(nix eval --raw --file "$repo_root/npins" "$pin.outPath")
	mkdir "$workspace/source"
	cp -R "$source_path"/. "$workspace/source/"
	chmod -R u+w "$workspace/source"
}

check_package() (
	local package=$1
	local patch_dir=$repo_root/packages/$package/patches
	local workspace patch_name
	workspace=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-quilt-$package.XXXXXX")
	trap 'rm -rf -- "$workspace"' EXIT

	validate_series "$patch_dir"
	prepare_source "$package" "$workspace"
	cp -R "$patch_dir" "$workspace/patches"
	chmod -R u+w "$workspace/patches"

	cd "$workspace/source"
	while IFS= read -r patch_name; do
		git apply --check "$workspace/patches/$patch_name"
		QUILT_PATCHES=$workspace/patches QUILTRC=$quiltrc quilt push >/dev/null
		QUILT_PATCHES=$workspace/patches QUILTRC=$quiltrc quilt refresh >/dev/null
	done <"$workspace/patches/series"

	if diff -ru "$patch_dir" "$workspace/patches"; then
		printf 'Quilt queue is current: %s\n' "$package"
	else
		printf 'Quilt queue needs a refresh: %s\n' "$package" >&2
		return 1
	fi
)

open_shell() {
	local package=$1
	local patch_dir=$repo_root/packages/$package/patches
	local workspace status=0
	workspace=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-quilt-$package.XXXXXX")

	validate_series "$patch_dir"
	prepare_source "$package" "$workspace"
	cd "$workspace/source"
	export QUILT_PATCHES=$patch_dir
	export QUILTRC=$quiltrc

	printf 'Source:  %s\nPatches: %s\n' "$PWD" "$QUILT_PATCHES"
	quilt push -a
	"${SHELL:-/bin/bash}" -i || status=$?
	printf 'Workspace kept at %s\n' "$PWD"
	return "$status"
}

main() {
	local action=${1:-}
	local package=${2:-}

	case $action in
		check)
			package=${package:-all}
			if [[ $package == all ]]; then
				for package in "${packages[@]}"; do
					check_package "$package"
				done
			elif source_pin "$package" >/dev/null; then
				check_package "$package"
			else
				die "Unknown package: $package"
			fi
			;;
		shell)
			source_pin "$package" >/dev/null || die "Unknown package: ${package:-<empty>}"
			open_shell "$package"
			;;
		-h | --help) usage ;;
		*)
			usage >&2
			return 2
			;;
	esac
}

main "$@"
