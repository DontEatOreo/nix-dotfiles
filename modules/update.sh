#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq gnused gnugrep nix-update
# shellcheck shell=bash

set -euo pipefail

cleanup() {
	if [ -f "temp-wrapper.nix" ]; then
		rm -f "temp-wrapper.nix"
	fi
}
trap cleanup EXIT

if [ "$#" -lt 1 ]; then
	echo "Usage: $0 <nix-file>"
	exit 1
fi

NIX_FILE="$1"
# Convert to absolute path
ABS_NIX_FILE=$(realpath "$NIX_FILE")

if [ ! -f "$ABS_NIX_FILE" ]; then
	echo "Error: File $NIX_FILE does not exist"
	exit 1
fi

# Extract owner and repo from the Nix file for verification
OWNER=$(grep 'owner = ' "$ABS_NIX_FILE" | sed -E 's/.*owner = "([^"]+)".*/\1/')
REPO=$(grep 'repo = ' "$ABS_NIX_FILE" | sed -E 's/.*repo = "([^"]+)".*/\1/')

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
	echo "Error: Could not extract owner/repo from $ABS_NIX_FILE"
	exit 1
fi

echo "Updating $ABS_NIX_FILE for $OWNER/$REPO..."

# Create temporary wrapper using callPackage with proper path escaping
cat >temp-wrapper.nix <<EOF
{ pkgs ? import <nixpkgs> {} }:
rec {
  ${REPO} = pkgs.callPackage ${ABS_NIX_FILE} {};
}
EOF

# Use nix-update with temporary file
nix-update --version=branch \
	-f ./temp-wrapper.nix \
	--override-filename "$ABS_NIX_FILE" \
	"${REPO}"
