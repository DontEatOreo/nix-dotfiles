#!/bin/bash
# shellcheck shell=bash
# Dispatch fake host commands for bootstrap simulation scenarios.

set -euo pipefail

SIMULATED_COMMAND_NAME="$(basename "$0")"
readonly SIMULATED_COMMAND_NAME

# Every fake executable is a symlink to this dispatcher. Dispatching by argv[0]
# keeps the simulated command surface in one auditable implementation.

trace_command() {
	{
		printf '%s' "${SIMULATED_COMMAND_NAME}"
		printf '\t%s' "$@"
		printf '\n'
	} >>"${BOOTSTRAP_SIMULATOR_TRACE}"
}

install_fake_executable() {
	local destination="$1"

	mkdir -p "$(dirname "${destination}")"
	ln -sf "${BOOTSTRAP_SIMULATOR_DISPATCHER}" "${destination}"
}

fail_for_scenario() {
	local failure_scenario="$1"
	local exit_status="$2"

	if [[ "${BOOTSTRAP_SIMULATOR_SCENARIO}" == "${failure_scenario}" ]]; then
		exit "${exit_status}"
	fi
}

argument_is_present() {
	local expected_argument="$1"
	shift
	local argument

	# Compare argv entries instead of matching "$*"; substring matching can make
	# an unrelated option value look like a bootstrap phase.
	for argument in "$@"; do
		if [[ "${argument}" == "${expected_argument}" ]]; then
			return 0
		fi
	done
	return 1
}

main() {
	local destination=''
	local executable

	case "${SIMULATED_COMMAND_NAME}" in
		uname)
			case "${1:-}" in
				-s) printf '%s\n' 'Darwin' ;;
				-m) printf '%s\n' 'arm64' ;;
				*) exit 64 ;;
			esac
			;;
		sw_vers)
			if [[ "${1:-}" != '-productVersion' ]]; then
				exit 64
			fi
			if [[ "${BOOTSTRAP_SIMULATOR_SCENARIO}" == 'old-macos' ]]; then
				printf '%s\n' '25.6'
			else
				printf '%s\n' '26.0'
			fi
			;;
		curl)
			trace_command "$@"
			fail_for_scenario 'download-failure' 11
			while (($#)); do
				if [[ "$1" == '-o' ]]; then
					destination="$2"
					break
				fi
				shift
			done
			[[ -n "${destination}" ]] || exit 64
			/bin/cp "${BOOTSTRAP_SIMULATOR_INSTALLER}" "${destination}"
			;;
		sudo)
			trace_command "$@"
			;;
		open)
			trace_command "$@"
			;;
		brew)
			trace_command "$@"
			case "${1:-}" in
				--prefix)
					printf '%s\n' "${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}"
					;;
				install)
					fail_for_scenario 'formula-failure' 31
					install_fake_executable \
						"${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}/bin/uv"
					;;
			esac
			;;
		uv)
			trace_command "$@"
			if [[ "${2:-}" == 'python' && "${3:-}" == 'install' ]]; then
				fail_for_scenario 'python-failure' 32
				install_fake_executable "${UV_PYTHON_BIN_DIR}/python3.14"
			elif [[ "${2:-}" == 'tool' && "${3:-}" == 'install' ]]; then
				fail_for_scenario 'tool-failure' 33
				for executable in ansible-galaxy ansible-lint ansible-playbook; do
					install_fake_executable "${UV_TOOL_BIN_DIR}/${executable}"
				done
			fi
			;;
		python3.14)
			trace_command "$@"
			;;
		ansible-playbook)
			if [[ "${1:-}" == '--version' ]]; then
				printf '%s\n' \
					'ansible-playbook [core 2.21.0]' \
					'  python version = 3.14.0 (fake bootstrap environment)'
				exit 0
			fi
			trace_command \
				"ANSIBLE_BECOME_ASK_PASS=${ANSIBLE_BECOME_ASK_PASS:-}" "$@"
			if argument_is_present 'stage-10,stage-20' "$@"; then
				fail_for_scenario 'userland-failure' 21
				if [[ "${BOOTSTRAP_SIMULATOR_SCENARIO}" != 'missing-just' ]]; then
					install_fake_executable \
						"${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}/bin/just"
				fi
				install_fake_executable \
					"${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}/bin/sops"
				install_fake_executable \
					"${BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX}/bin/gtimeout"
			elif argument_is_present 'host' "$@"; then
				fail_for_scenario 'host-failure' 23
			fi
			;;
		sops)
			trace_command "$@"
			fail_for_scenario 'secrets-failure' 35
			;;
		gtimeout)
			trace_command "$@"
			shift 2
			"$@"
			;;
		ansible-galaxy)
			trace_command "$@"
			fail_for_scenario 'collections-failure' 34
			;;
		ansible-lint)
			trace_command "$@"
			;;
		just)
			trace_command "$@"
			fail_for_scenario 'apply-failure' 22
			;;
		*)
			printf 'unexpected simulated command: %s\n' \
				"${SIMULATED_COMMAND_NAME}" >&2
			exit 64
			;;
	esac
}

main "$@"
