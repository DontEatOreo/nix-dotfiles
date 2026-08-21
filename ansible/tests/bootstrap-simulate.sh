#!/bin/bash
# shellcheck shell=bash
# Run the real bootstrap orchestration against disposable fake host tools.

set -euo pipefail

readonly -a SUPPORTED_SCENARIOS=(
	'success'
	'existing-homebrew'
	'ansible-args'
	'old-macos'
	'download-failure'
	'checksum-failure'
	'formula-failure'
	'python-failure'
	'tool-failure'
	'collections-failure'
	'userland-failure'
	'secrets-failure'
	'apply-failure'
	'host-failure'
	'missing-just'
)

readonly -a SIMULATED_COMMANDS=(
	'curl'
	'open'
	'sudo'
	'uname'
	'sw_vers'
)

readonly -a REPOSITORY_FIXTURES=(
	'ansible/bootstrap.sh'
	'ansible/site.yml'
	'ansible/requirements.yml'
	'Justfile'
	'secrets/secrets.yaml'
	'dotfiles/dot_local/bin/executable_sops-age-key-1password'
)

SIMULATOR_DIRECTORY="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_REPOSITORY_ROOT="$(cd -P "${SIMULATOR_DIRECTORY}/../.." && pwd -P)"
readonly SIMULATOR_DIRECTORY SOURCE_REPOSITORY_ROOT
readonly SIMULATION_SCENARIO="${1:-success}"

scenario_is_supported() {
	local supported_scenario

	for supported_scenario in "${SUPPORTED_SCENARIOS[@]}"; do
		if [[ "${SIMULATION_SCENARIO}" == "${supported_scenario}" ]]; then
			return 0
		fi
	done
	return 1
}

print_usage() {
	local IFS='|'
	printf 'usage: %s [%s]\n' "$0" "${SUPPORTED_SCENARIOS[*]}" >&2
}

populate_simulated_repository() {
	local fixture_path

	for fixture_path in "${REPOSITORY_FIXTURES[@]}"; do
		mkdir -p "$(dirname "${SIMULATED_REPOSITORY_ROOT}/${fixture_path}")"
		ln -s \
			"${SOURCE_REPOSITORY_ROOT}/${fixture_path}" \
			"${SIMULATED_REPOSITORY_ROOT}/${fixture_path}"
	done
}

link_simulated_commands() {
	local command_name

	for command_name in "${SIMULATED_COMMANDS[@]}"; do
		ln -s \
			"${FAKE_COMMAND_DISPATCHER}" \
			"${SIMULATED_COMMAND_DIRECTORY}/${command_name}"
	done
}

configure_installer_checksum() {
	local checksum_output

	if [[ "${SIMULATION_SCENARIO}" == 'checksum-failure' ]]; then
		HOMEBREW_INSTALLER_CHECKSUM='0000000000000000000000000000000000000000000000000000000000000000'
	elif command -v sha256sum >/dev/null 2>&1; then
		checksum_output="$(sha256sum "${FAKE_HOMEBREW_INSTALLER}")"
		HOMEBREW_INSTALLER_CHECKSUM="${checksum_output%% *}"
	else
		checksum_output="$(shasum -a 256 "${FAKE_HOMEBREW_INSTALLER}")"
		HOMEBREW_INSTALLER_CHECKSUM="${checksum_output%% *}"
	fi
	export HOMEBREW_INSTALLER_CHECKSUM
}

# Reject typos before mktemp so even invalid invocations leave no artifacts.
if ! scenario_is_supported; then
	print_usage
	exit 64
fi

SIMULATION_ROOT="$(
	mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap-simulation.XXXXXX"
)"
readonly SIMULATION_ROOT
# Called by the signal and exit traps below.
# shellcheck disable=SC2329
cleanup_simulation() {
	rm -R "${SIMULATION_ROOT}"
}
trap cleanup_simulation EXIT
trap 'exit 1' HUP INT TERM

readonly SIMULATED_HOME="${SIMULATION_ROOT}/home"
readonly SIMULATED_COMMAND_DIRECTORY="${SIMULATION_ROOT}/bin"
readonly SIMULATED_HOMEBREW_PREFIX="${SIMULATION_ROOT}/homebrew"
readonly SIMULATED_REPOSITORY_ROOT="${SIMULATION_ROOT}/repo"
readonly COMMAND_TRACE_FILE="${SIMULATION_ROOT}/trace.tsv"
FAKE_COMMAND_DISPATCHER="${SOURCE_REPOSITORY_ROOT}/"
FAKE_COMMAND_DISPATCHER+='ansible/tests/fixtures/bootstrap/fake-command.sh'
readonly FAKE_COMMAND_DISPATCHER
FAKE_HOMEBREW_INSTALLER="${SOURCE_REPOSITORY_ROOT}/"
FAKE_HOMEBREW_INSTALLER+='ansible/tests/fixtures/bootstrap/'
FAKE_HOMEBREW_INSTALLER+='fake-homebrew-installer.sh'
readonly FAKE_HOMEBREW_INSTALLER

mkdir -p \
	"${SIMULATED_HOME}" \
	"${SIMULATED_COMMAND_DIRECTORY}" \
	"${SIMULATED_REPOSITORY_ROOT}" \
	"${SIMULATION_ROOT}/tmp"
: >"${COMMAND_TRACE_FILE}"

# Use a minimal disposable repository so local Ansible caches cannot affect
# simulated fresh-host decisions. Listing fixtures above keeps this isolation
# boundary explicit and reviewable.
populate_simulated_repository
link_simulated_commands
if [[ "${SIMULATION_SCENARIO}" == 'existing-homebrew' ]]; then
	mkdir -p "${SIMULATED_HOMEBREW_PREFIX}/bin"
	ln -s \
		"${FAKE_COMMAND_DISPATCHER}" \
		"${SIMULATED_HOMEBREW_PREFIX}/bin/brew"
fi

export HOME="${SIMULATED_HOME}"
export PATH="${SIMULATED_COMMAND_DIRECTORY}:/usr/bin:/bin:/usr/sbin:/sbin"
export TMPDIR="${SIMULATION_ROOT}/tmp"
export BOOTSTRAP_SIMULATOR_DISPATCHER="${FAKE_COMMAND_DISPATCHER}"
export BOOTSTRAP_SIMULATOR_HOMEBREW_PREFIX="${SIMULATED_HOMEBREW_PREFIX}"
export BOOTSTRAP_SIMULATOR_INSTALLER="${FAKE_HOMEBREW_INSTALLER}"
export BOOTSTRAP_SIMULATOR_SCENARIO="${SIMULATION_SCENARIO}"
export BOOTSTRAP_SIMULATOR_TRACE="${COMMAND_TRACE_FILE}"

configure_installer_checksum

# This is the simulator's only production-code hatch: sourcing lets it replace
# the fixed Homebrew prefix while every other production function runs as-is.
# The source guard in bootstrap.sh prevents an accidental nested bootstrap.
# shellcheck source=../bootstrap.sh
source "${SIMULATED_REPOSITORY_ROOT}/ansible/bootstrap.sh"
# Called by main through the production function lookup.
# shellcheck disable=SC2329
resolve_homebrew_prefix() {
	printf '%s\n' "${SIMULATED_HOMEBREW_PREFIX}"
}

run_simulation() {
	local -a bootstrap_arguments=(--setup)
	local exit_status

	if [[ "${SIMULATION_SCENARIO}" == 'ansible-args' ]]; then
		bootstrap_arguments=(--check --tags tools)
	fi

	printf '==> Running bootstrap simulation: %s\n' "${SIMULATION_SCENARIO}"
	set +e
	(
		set -e
		# A simulator launched from a terminal must still follow non-interactive
		# branches; otherwise a failure could prompt or open a real host app.
		main "${bootstrap_arguments[@]}" </dev/null
	)
	exit_status=$?
	set -e

	printf '\n==> Disposable host command trace\n'
	awk -F '\t' '
    {
      printf "%02d  %s", NR, $1
      for (i = 2; i <= NF; i++) printf " %s", $i
      printf "\n"
    }
  ' "${COMMAND_TRACE_FILE}"
	printf '\n==> Simulation exit status: %d\n' "${exit_status}"
	return "${exit_status}"
}

run_simulation
