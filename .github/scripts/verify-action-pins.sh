#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail
shopt -s extglob

mapfile -d '' workflow_files < <(
	git ls-files -z --cached --others --exclude-standard -- \
		'.github/**/*.yaml' '.github/**/*.yml'
)

mapfile -t action_refs < <(
	grep -hE '^[[:space:]]*uses:' "${workflow_files[@]}" |
		while IFS= read -r line; do
			value=${line#*:}
			value=${value%%#*}
			value=${value##+([[:space:]])}
			value=${value%%+([[:space:]])}
			value=${value#\"}
			value=${value%\"}
			value=${value#\'}
			value=${value%\'}
			printf '%s\n' "${value}"
		done |
		sort -u
)

for action_ref in "${action_refs[@]}"; do
	case "${action_ref}" in
		./* | docker://*) continue ;;
	esac

	if [[ ! ${action_ref} =~ ^([^/[:space:]]+/[^/@[:space:]]+)(/[^@[:space:]]+)?@([0-9a-f]{40})$ ]]; then
		printf 'Action reference is not pinned to a full commit SHA: %s\n' "${action_ref}" >&2
		exit 1
	fi

	repository=${BASH_REMATCH[1]}
	commit=${BASH_REMATCH[3]}
	if ! gh api --silent "repos/${repository}/commits/${commit}"; then
		printf 'Action reference does not resolve to a GitHub commit: %s\n' "${action_ref}" >&2
		exit 1
	fi

	printf 'Verified %s\n' "${action_ref}"
done
