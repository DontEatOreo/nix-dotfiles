#!/bin/sh
# shellcheck shell=sh

set -eu

fail() {
	printf 'dotfiles smoke test: %s\n' "$1" >&2
	exit 1
}

[ "$(id -u)" -ne 0 ] || fail 'container is running as root'

for directory in "${HOME}" /workspace/dotfiles; do
	[ -w "${directory}" ] || fail "directory is not writable: ${directory}"
done

for path in \
	"${HOME}/.bashrc" \
	"${HOME}/.gitconfig" \
	"${HOME}/.ssh/config" \
	"${HOME}/.zshrc"; do
	[ -f "${path}" ] || fail "expected applied dotfile is missing: ${path}"
done

for command in ansible-lint ansible-playbook terminal-theme-run yamllint; do
	command -v "${command}" >/dev/null 2>&1 || fail "command is missing: ${command}"
	"${command}" --version >/dev/null
done

command -v phone-mirror >/dev/null 2>&1 || fail 'command is missing: phone-mirror'

for path in \
	/workspace/dotfiles/packages/terminal-theme-tools/.zig-cache \
	/workspace/dotfiles/packages/terminal-theme-tools/zig-pkg; do
	[ ! -e "${path}" ] || fail "generated build cache leaked into image: ${path}"
done

if command -v starship >/dev/null 2>&1; then
	fail 'starship should not be installed by the repo-tools-only test'
fi
