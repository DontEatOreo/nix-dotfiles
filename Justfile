#!/usr/bin/env -S just --justfile

set minimum-version := "1.58.0"
set unstable
set lists
set default-list
set default-script
set script-interpreter := ['bash', '-euo', 'pipefail']

import 'just/dev.just'
import 'just/secrets.just'
import 'just/setup.just'
import 'just/spectrum.just'
import 'just/system.just'

podman := split(env("PODMAN", "podman"))

host_os := os()
repo_dir := justfile_directory()

homebrew_prefix := env("HOMEBREW_PREFIX", if host_os == "macos" { "/opt/homebrew" } else { "/home/linuxbrew/.linuxbrew" })
homebrew_gnu_formulae := ['coreutils', 'findutils', 'gnu-sed', 'grep', 'gawk', 'gnu-tar', 'gnu-which', 'diffutils', 'make']
homebrew_gnu_path := if host_os == "macos" { join_list(append("/libexec/gnubin", prepend(homebrew_prefix / "opt/", homebrew_gnu_formulae)), PATH_VAR_SEP) + PATH_VAR_SEP } else { "" }
homebrew_path := homebrew_gnu_path + homebrew_prefix / "bin" + PATH_VAR_SEP + homebrew_prefix / "sbin"
nix_bin_dir := "/nix/var/nix/profiles/default/bin"
nix_profile_bin_dir := home_directory() / ".nix-profile/bin"
nixos_profile_bin_dir := "/run/current-system/sw/bin"

export PATH := homebrew_path + PATH_VAR_SEP + nix_bin_dir + PATH_VAR_SEP + nix_profile_bin_dir + PATH_VAR_SEP + nixos_profile_bin_dir + PATH_VAR_SEP + env("PATH", "")
# Development recipes are reproducible by default; dependency changes must be
# made explicitly with uv outside the task runner.
export UV_LOCKED := "1"

alias a := apply
alias build := spectrum-build
alias c := check
alias cf := check-format
alias ck := check
alias diff := dotfiles-diff
alias f := fmt
alias h := help
alias l := lint
alias nx := nix
alias r := reboot
alias s := setup
alias typecheck := python-typecheck
alias up := update
alias validate := spectrum-validate
alias w := watch

help_target(recipe) := if recipe == 'a' { 'apply' } else if recipe == 'build' { 'spectrum-build' } else if recipe == 'c' || recipe == 'ck' { 'check' } else if recipe == 'cf' { 'check-format' } else if recipe == 'diff' { 'dotfiles-diff' } else if recipe == 'f' { 'fmt' } else if recipe == 'h' { 'help' } else if recipe == 'l' { 'lint' } else if recipe == 'nx' { 'nix' } else if recipe == 'r' { 'reboot' } else if recipe == 's' { 'setup' } else if recipe == 'typecheck' { 'python-typecheck' } else if recipe == 'up' { 'update' } else if recipe == 'validate' { 'spectrum-validate' } else if recipe == 'w' { 'watch' } else { recipe }

# List recipes or show detailed usage for one recipe.
[arg('recipe', help='Recipe to explain; omit to list all recipes')]
[group('system')]
help recipe='':
    {{ quote(just_executable()) }} \
      --justfile {{ quote(justfile()) }} \
      {{ quote(if recipe != '' { ['--usage', help_target(recipe)] } else { ['--list', '--list-submodules'] }) }}
