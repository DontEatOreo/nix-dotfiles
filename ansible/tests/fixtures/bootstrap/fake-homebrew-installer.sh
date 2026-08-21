#!/bin/bash
# shellcheck shell=bash
# Install a fake Homebrew executable in the disposable simulation prefix.

set -euo pipefail

printf 'homebrew-installer\tNONINTERACTIVE=%s\n' \
	"${NONINTERACTIVE:-}" >>"${BOOTSTRAP_SIMULATOR_TRACE}"
mkdir -p "${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}/bin"
ln -sf \
	"${BOOTSTRAP_SIMULATOR_DISPATCHER}" \
	"${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}/bin/brew"
