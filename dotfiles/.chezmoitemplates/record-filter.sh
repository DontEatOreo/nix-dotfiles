#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

readonly selector=$1
readonly index=$2
readonly render=$3
readonly source_dir=$4

render_body() {
	if [[ $render == true ]]; then
		chezmoi --source "$source_dir" execute-template
	else
		cat
	fi
}

sops decrypt \
	--input-type yaml \
	--output-type json \
	--extract "$selector" \
	/dev/stdin |
	jq -j --argjson index "$index" '.[$index].body' |
	render_body
