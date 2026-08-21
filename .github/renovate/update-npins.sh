#!/usr/bin/env bash

set -euo pipefail

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root"

# Renovate updates the discovered version or revision field before post-upgrade
# tasks run. Restore the coherent lock first so npins sees the change and owns
# the revision, fetch URL, and hash as one atomic update.
git restore --source=HEAD --staged --worktree -- npins/sources.json
nix shell nixpkgs#npins --command npins update
bash .github/renovate/check-npins.sh
