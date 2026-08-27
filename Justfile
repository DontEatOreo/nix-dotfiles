#!/usr/bin/env -S just --justfile

set minimum-version := "1.58.0"
set unstable
set lists
set default-list
set default-script
set script-interpreter := ['bash', '-euo', 'pipefail']

import 'just/secrets.just'

image_name := env("SPECTRUM_IMAGE_NAME", "spectrum")
local_ref := "localhost/" + image_name + ":latest_linux_amd64"
compose := split(env("COMPOSE", "podman-compose"))
podman := split(env("PODMAN", "podman"))
determinate_nix_installer_url := "https://install.determinate.systems/nix"
determinate_nix_pkg_url := "https://install.determinate.systems/determinate-pkg/stable/Universal"
determinate_nix_team_id := "X3JQ4VPJZ6"

host_os := os()
repo_dir := justfile_directory()

homebrew_prefix := env("HOMEBREW_PREFIX", if host_os == "macos" { "/opt/homebrew" } else { "/home/linuxbrew/.linuxbrew" })
homebrew_gnu_formulae := ['coreutils', 'findutils', 'gnu-sed', 'grep', 'gawk', 'gnu-tar', 'gnu-which', 'diffutils', 'make']
homebrew_gnu_path := if host_os == "macos" { join_list(append("/libexec/gnubin", prepend(homebrew_prefix / "opt/", homebrew_gnu_formulae)), PATH_VAR_SEP) + PATH_VAR_SEP } else { "" }
homebrew_path := homebrew_gnu_path + homebrew_prefix / "bin" + PATH_VAR_SEP + homebrew_prefix / "sbin"
nix_bin_dir := "/nix/var/nix/profiles/default/bin"
nix_bin := nix_bin_dir / "nix"
nix_profile_bin_dir := home_directory() / ".nix-profile/bin"
nixos_profile_bin_dir := "/run/current-system/sw/bin"
nix_profile_tools := ['deadnix:deadnix', 'nh:nh', 'nil:nil', 'nix-instantiate:nix', 'nom:nix-output-monitor', 'nix-tree:nix-tree', 'nixd:nixd', 'nixfmt:nixfmt', 'statix:statix']

doctor_setup_commands := ['bash', 'curl', 'git', 'sudo']
doctor_format_commands := ['git', 'nix']
doctor_ansible_commands := ['ansible-doc', 'ansible-galaxy', 'ansible-lint', 'ansible-playbook', 'yamllint']
doctor_lint_commands := ['actionlint', 'bundle', 'chezmoi', 'deadnix', 'diffstat', 'jq', 'luacheck', 'nix-instantiate', 'quilt', 'ruby', 'rumdl', 'shellcheck', 'statix', 'taplo', 'uv', 'zig', 'zizmor'] ++ (if host_os == "linux" { ['hadolint'] } else { [] }) ++ doctor_format_commands ++ doctor_ansible_commands
[private]
doctor_sops_commands := ['bash', 'sops'] ++ (if host_os == "macos" { ['op'] } else { [] })
[private]
doctor_records_commands := doctor_sops_commands ++ ['jq', 'ruby']
doctor_all_commands := doctor_lint_commands ++ doctor_sops_commands ++ ['curl', 'sudo', 'watchexec']

export PATH := homebrew_path + PATH_VAR_SEP + nix_bin_dir + PATH_VAR_SEP + nix_profile_bin_dir + PATH_VAR_SEP + nixos_profile_bin_dir + PATH_VAR_SEP + env("PATH", "")
# Development recipes are reproducible by default; dependency changes must be
# made explicitly with uv outside the task runner.
export UV_LOCKED := "1"

alias a := apply
alias c := check
alias cf := check-format
alias ck := check
alias f := fmt
alias l := lint
alias nx := nix
alias r := reboot
alias s := setup
alias up := update
alias w := watch

# Check commands required for a workflow profile.
[arg('profile', pattern=['status', 'reboot', 'install', 'build', 'setup', 'apply', 'records', 'sops', 'shell', 'spectrum', 'fmt', 'lint', 'zig', 'ansible', 'bun', 'smoke', 'nix', 'watch', 'check', 'all'], help='status, reboot, install, build, setup, apply, records, sops, shell, spectrum, fmt, lint, zig, ansible, bun, smoke, nix, watch, check, or all')]
[group('system')]
doctor profile="setup":
    profile={{ quote(profile) }}
    host_os={{ quote(host_os) }}
    commands=()
    podman_command=({{ quote(podman) }})
    compose_command=({{ quote(compose) }})

    linux_commands() {
      if [[ $host_os == linux ]]; then
        commands=("$@")
      else
        printf 'Skipping Linux-only dependency check for workflow %q on %s.\n' "$profile" "$host_os"
      fi
    }

    case "$profile" in
      status) linux_commands bootc sudo ;;
      reboot) linux_commands systemctl ;;
      install) linux_commands bootc sudo ;;
      build) commands=("${podman_command[0]}") ;;
      spectrum) commands=(bluebuild check-jsonschema jq "${podman_command[0]}" skopeo) ;;
      setup) commands=({{ quote(doctor_setup_commands) }}) ;;
      apply)
        commands=(chezmoi {{ quote(doctor_records_commands) }})
        ;;
      records)
        commands=({{ quote(doctor_records_commands) }})
        ;;
      sops)
        commands=({{ quote(doctor_sops_commands) }})
        ;;
      shell) commands=(shellcheck shfmt) ;;
      fmt) commands=({{ quote(doctor_format_commands) }}) ;;
      lint | check) commands=({{ quote(doctor_lint_commands) }}) ;;
      zig) commands=(zig) ;;
      ansible) commands=({{ quote(doctor_ansible_commands) }}) ;;
      bun) commands=(bun) ;;
      smoke) commands=("${compose_command[0]}") ;;
      nix) commands=(bash curl sudo) ;;
      watch) commands=(watchexec) ;;
      all)
        commands=({{ quote(doctor_all_commands) }} "${podman_command[0]}" "${compose_command[0]}")
        if [[ $host_os == linux ]]; then
          commands+=(bootc systemctl)
        fi
        ;;
    esac

    missing=0
    for command in "${commands[@]}"; do
      if ! command -v "$command" >/dev/null 2>&1; then
        printf 'missing command: %s\n' "$command" >&2
        missing=1
      fi
    done
    exit "$missing"

[macos]
[private]
[shell]
_linux-only recipe:
    @printf 'Skipping `just %s`: this workflow is only supported on Linux.\n' {{ quote(recipe) }}

# Show bootc and image metadata status.
[group('system')]
[linux]
[shell]
status: (doctor 'status')
    sudo bootc status
    @if [ -r /usr/share/ublue-os/image-info.json ] && command -v jq >/dev/null 2>&1; then \
      jq . /usr/share/ublue-os/image-info.json; \
    fi

[group('system')]
[macos]
status: (_linux-only recipe_name())

# Reclaim disposable Podman, Nix, tool, user, and journal data.
[confirm('Remove unused Podman data, old Nix generations, caches, and archived journals?')]
[group('system')]
[linux]
clean:
    cache_dir={{ quote(cache_directory()) }}
    home_dir={{ quote(home_directory()) }}
    tracked_paths=(/var "$home_dir" /nix /run "$cache_dir")

    filesystem_usage_bytes() {
      local path filesystem used total=0
      local -A seen_filesystems=()
      for path in "${tracked_paths[@]}"; do
        [[ -e $path ]] || continue
        read -r filesystem used < <(
          df --block-size=1 --output=source,used -- "$path" | tail -n 1
        )
        [[ -v seen_filesystems[$filesystem] ]] && continue
        seen_filesystems[$filesystem]=1
        total=$((total + used))
      done
      printf '%s\n' "$total"
    }

    human_bytes() {
      if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$1"
      else
        printf '%s bytes\n' "$1"
      fi
    }

    report_usage_delta() {
      local delta=$1 context=$2
      if ((delta >= 0)); then
        printf 'Actual filesystem space reclaimed: %s (%s bytes)\n' "$(human_bytes "$delta")" "$delta"
      else
        delta=$((-delta))
        printf 'Filesystem usage grew during %s: %s (%s bytes)\n' "$context" "$(human_bytes "$delta")" "$delta"
      fi
    }

    measure_cleanup() {
      local label=$1
      shift
      local before after reclaimed
      sync
      before=$(filesystem_usage_bytes)
      printf '\n==> %s\n' "$label"
      if ! "$@"; then
        printf 'Cleanup stage failed: %s\n' "$label" >&2
        return 1
      fi
      sync
      after=$(filesystem_usage_bytes)
      reclaimed=$((before - after))
      report_usage_delta "$reclaimed" 'this stage'
    }

    clean_podman() {
      {{ quote(podman) }} system prune --all --force |
        sed 's/^Total reclaimed space:/Podman logical reclaimed total (not physical disk usage):/'
    }

    clean_podman_root() {
      # Rootful Podman performs Spectrum builds. Failed commits can leave
      # Buildah working containers behind, and ordinary system prune does not
      # remove them without --build.
      sudo {{ quote(podman) }} system prune --force --build |
        sed 's/^Total reclaimed space:/Podman logical reclaimed total (not physical disk usage):/'
    }

    clean_buildah_caches() {
    local buildah_tmp=/var/tmp
    # Persistent cache mounts and interrupted layer commits live outside the
    # containers-storage graph, so Podman's prune cannot account for them.
    sudo find "$buildah_tmp" -mindepth 1 -maxdepth 1 -name 'buildah*' \
      -exec rm -rf -- {} + ||
      printf 'Some active Buildah temporary paths could not be removed.\n' >&2
    }

    clean_nix() {
      nh clean all --keep 1
    }

    clean_tool_caches() {
    if command -v uv >/dev/null 2>&1; then
      if ! uv cache prune --force; then
        printf 'uv cache prune failed; the full user-cache cleanup will retry it.\n' >&2
      fi
    fi
    if command -v go >/dev/null 2>&1; then
      go clean -cache -testcache
    fi
    if command -v brew >/dev/null 2>&1; then
      brew cleanup --prune=all -s
    fi
    }

    clean_user_cache() {
    case "$cache_dir" in
      '' | / | "$home_dir")
        printf 'Refusing unsafe cache directory: %q\n' "$cache_dir" >&2
        exit 2
        ;;
    esac
    if [[ -d $cache_dir ]]; then
      if ! find "$cache_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; then
        printf 'Retrying user-cache cleanup with elevated privileges.\n' >&2
        sudo find "$cache_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
      fi
    fi
    }

    clean_journal() {
    journal_size_kib=0
    for journal_dir in /var/log/journal /run/log/journal; do
      if [[ -d $journal_dir ]]; then
        directory_size_kib=$(sudo du -sk "$journal_dir" | awk '{ print $1 }')
        journal_size_kib=$((journal_size_kib + directory_size_kib))
      fi
    done
    journal_threshold_kib=$((1024 * 1024))

    if ((journal_size_kib > journal_threshold_kib)); then
      sudo journalctl --rotate
      sudo journalctl --vacuum-size=500M
    else
      printf 'Journal uses at most 1 GiB; skipping cleanup.\n'
    fi
    }

    sync
    total_before=$(filesystem_usage_bytes)
    measure_cleanup 'Rootless Podman' clean_podman
    measure_cleanup 'Rootful Podman' clean_podman_root
    measure_cleanup 'Buildah temporary caches' clean_buildah_caches
    measure_cleanup 'Nix generations and store' clean_nix
    measure_cleanup 'Tool caches' clean_tool_caches
    measure_cleanup 'User cache' clean_user_cache
    measure_cleanup 'Archived journals' clean_journal
    sync
    total_after=$(filesystem_usage_bytes)
    total_reclaimed=$((total_before - total_after))
    printf '\n==> Cleanup total\n'
    report_usage_delta "$total_reclaimed" cleanup

[group('system')]
[macos]
clean: (_linux-only recipe_name())

# Reboot the host.
[confirm('Reboot this host now?')]
[group('system')]
[linux]
reboot: (doctor 'reboot')
    systemctl reboot

[group('system')]
[macos]
reboot: (_linux-only recipe_name())

# Validate the recipe and enforce the Renovate-managed base digest lock.
[group('spectrum')]
[linux]
spectrum-validate: (doctor 'nix')
    nix develop .#operations --command \
      {{ quote(just_executable()) }} --justfile {{ quote(justfile()) }} _spectrum-validate

[linux]
[private]
_spectrum-validate: (doctor 'spectrum')
    generated=$(mktemp)
    trap 'rm -f "$generated"' EXIT
    check-jsonschema \
      --base-uri https://schema.blue-build.org/ \
      --schemafile https://schema.blue-build.org/recipe-v2.json \
      bluebuild/recipes/spectrum.yml
    check-jsonschema \
      --base-uri https://schema.blue-build.org/ \
      --schemafile https://schema.blue-build.org/stage-v1.json \
      bluebuild/recipes/spectrum/stages/*.yml
    check-jsonschema \
      --base-uri https://schema.blue-build.org/ \
      --schemafile https://schema.blue-build.org/module-list-v1.json \
      bluebuild/recipes/spectrum/modules/*.yml
    bash bluebuild/recipes/spectrum/sync-sources.sh --check
    # BlueBuild's feature-gated v2 parser is ready, but its validate command
    # still hardcodes the v1 schema. The official v2 schema is checked above.
    bluebuild generate --skip-validation --output "$generated" bluebuild/recipes/spectrum.yml
    bluebuild_revision=$(jq -er '.pins["bluebuild-cli"].revision' npins/sources.json)
    grep -Fq "COPY --from=ghcr.io/blue-build/cli:${bluebuild_revision}-installer" "$generated"
    grep -Fq '/out/bluebuild /bins/bluebuild' "$generated"
    grep -Fq 'cp /tmp/bins/* /usr/bin/' "$generated"
    grep -Fq -- '--mount=type=cache,sharing=locked,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache-spectrum-' "$generated"
    grep -Fq -- '--mount=type=cache,sharing=locked,dst=/var/cache/libdnf5,id=dnf-cache-spectrum-' "$generated"
    grep -Fq 'bluebuild/recipes/spectrum/sources/astral.json /src/sources.json' "$generated"
    grep -Fq 'bluebuild/recipes/spectrum/sources/ghostty.json /src/sources.json' "$generated"
    grep -Fq 'bluebuild/recipes/spectrum/sources/kanata.json /src/sources.json' "$generated"
    grep -Fq 'packages/hyper-window-tiling/package.json /src/package.json' "$generated"
    grep -Fq -- '--mount=type=cache,id=spectrum-ghostty-zig-global-v1,sharing=locked,target=/build/zig-cache' "$generated"
    grep -Fq -- '--mount=type=cache,id=spectrum-ghostty-zig-local-v1,sharing=locked,target=/build/source/.zig-cache' "$generated"
    grep -Fq -- '--mount=type=cache,id=spectrum-hyper-window-tiling-bun-v1,sharing=locked,target=/root/.bun/install/cache' "$generated"
    grep -Fq -- '--mount=type=cache,id=spectrum-kanata-target-v1,sharing=locked,target=/build/kanata-source/target' "$generated"
    ! grep -Fq 'npins/sources.json /src/' "$generated"
    locked=$(< bluebuild/recipes/spectrum.lock)
    resolved=$(skopeo inspect "docker://${locked%@*}" | jq -r .Digest)
    [[ "$locked" == *@$resolved ]] || {
      printf 'base image lock mismatch: %s resolves to %s\n' "$locked" "$resolved" >&2
      exit 1
    }
    tagged=${locked%@*}
    expected_arg="${tagged%:*}@${locked##*@}"
    grep -Fq "ARG BASE_IMAGE=\"$expected_arg\"" "$generated"
    grep -Fq -- '-Dcpu=baseline' "$generated"
    ! grep -qw akmods bluebuild/recipes/spectrum.yml "$generated"

[group('spectrum')]
[macos]
spectrum-validate: (_linux-only recipe_name())

# Build the local Spectrum image from the BlueBuild recipe v2 definition.
[group('spectrum')]
[linux]
spectrum-build: (doctor 'nix')
    nix develop .#operations --command \
      {{ quote(just_executable()) }} --justfile {{ quote(justfile()) }} _spectrum-build

[linux]
[private]
_spectrum-build: _spectrum-validate
    bluebuild build --skip-validation --no-sign bluebuild/recipes/spectrum.yml

[group('spectrum')]
[macos]
spectrum-build: (_linux-only recipe_name())

# Build and run the complete local pre-publish validation gate.
[group('spectrum')]
[linux]
spectrum-stage: spectrum-build && (spectrum-inspect local_ref)

[group('spectrum')]
[macos]
spectrum-stage: (_linux-only recipe_name())

# Inspect a built image with bootc and the bundled application smoke tests.
[arg('target', help='Built image reference to inspect')]
[group('spectrum')]
[linux]
spectrum-inspect target=local_ref: (doctor 'build')
    {{ quote(podman) }} run --rm {{ quote(target) }} bootc container lint --fatal-warnings
    {{ quote(podman) }} run --rm --entrypoint ghostty {{ quote(target) }} +version
    {{ quote(podman) }} run --rm --entrypoint kanata {{ quote(target) }} --version
    {{ quote(podman) }} run --rm --entrypoint bluebuild {{ quote(target) }} --version
    {{ quote(podman) }} run --rm --entrypoint bluebuild {{ quote(target) }} recipe --help >/dev/null

[arg('target', help='Built image reference to inspect')]
[group('spectrum')]
[macos]
spectrum-inspect target=local_ref: (_linux-only recipe_name())

# Build the Fedora smoke-test image and run its default validation command.
[group('containers')]
smoke: (doctor 'smoke')
    {{ quote(compose) }} build
    {{ quote(compose) }} run --rm -T fedora

# Open an interactive shell in the Fedora smoke-test image.
[group('containers')]
smoke-shell: (doctor 'smoke')
    {{ quote(compose) }} --profile shell run --rm fedora-shell

# Install Nix on Linux, accounting for immutable composefs hosts.
[linux]
[private]
_ensure-nix:
    if [[ ! -e /nix ]] &&
      command -v rpm-ostree >/dev/null 2>&1 &&
      findmnt --noheadings --output SOURCE,FSTYPE,OPTIONS / | grep -Eq '(^|[[:space:]])composefs([[:space:]]|$)'; then
      printf '%s\n' 'This composefs ostree host needs /nix in the booted image before installing Nix.' >&2
      printf '%s\n' 'Rebuild and boot Spectrum with the /nix mountpoint, then rerun just nix.' >&2
      exit 1
    fi

    if ! command -v nix >/dev/null 2>&1; then
      plan=linux
      if command -v rpm-ostree >/dev/null 2>&1; then
        plan=ostree
      fi
      curl --proto '=https' --tlsv1.2 -fsSL {{ quote(determinate_nix_installer_url) }} |
        sh -s -- install "$plan" --determinate --no-confirm --no-modify-profile
    fi

# Install the signed, notarized Determinate package recommended for macOS.
[macos]
[private]
_ensure-nix:
    if ! command -v nix >/dev/null 2>&1; then
      scratch=$(mktemp -d "${TMPDIR:-/tmp}/determinate.XXXXXXXXXX")
      trap 'rm -rf "$scratch"' EXIT
      pkg="$scratch/Determinate.pkg"

      curl --proto '=https' --tlsv1.2 -fsSL \
        {{ quote(determinate_nix_pkg_url) }} \
        --output "$pkg"
      signature=$(spctl -a -vv -t install "$pkg" 2>&1)
      actual_team_id=$(awk -F '[()]' '/origin=/ { print $(NF - 1) }' <<<"$signature")
      if [[ $actual_team_id != {{ quote(determinate_nix_team_id) }} ]]; then
        printf 'Determinate.pkg Team ID mismatch: expected %s, got %s\n' \
          {{ quote(determinate_nix_team_id) }} "${actual_team_id:-unknown}" >&2
        exit 1
      fi
      sudo /usr/sbin/installer -verboseR -pkg "$pkg" -tgt /
    fi

# Show the installed distribution, enabled features, and daemon status.
[group('system')]
determinate-status: (doctor 'nix') _ensure-nix
    nix --version
    determinate-nixd version
    determinate-nixd status

# Upgrade installer-managed Determinate Nix (NixOS is updated through its flake lock).
[confirm('Upgrade this installer-managed Determinate Nix installation?')]
[group('system')]
determinate-upgrade: (doctor 'nix') _ensure-nix
    if [[ -e /etc/NIXOS ]]; then
      printf '%s\n' 'NixOS manages Determinate declaratively; update nix/nixos/flake.lock and rebuild instead.' >&2
      exit 1
    fi
    sudo determinate-nixd upgrade

# Replace incorrect Nix expression hashes, prompting before each edit by default.
[group('dev')]
determinate-fix-hashes *args: (doctor 'nix') _ensure-nix
    determinate-nixd fix hashes {{ quote(args) }}

# Install Nix on the live host and ensure Nix profile tools exist.
[group('setup')]
nix: (doctor 'nix') _ensure-nix
    nix_profile_bin_dir={{ quote(nix_profile_bin_dir) }}
    nix_bin={{ quote(nix_bin) }}
    if [[ ! -x $nix_bin ]]; then
      nix_bin=$(command -v nix)
    fi

    missing=()
    for spec in {{ quote(nix_profile_tools) }}; do
      bin=${spec%%:*}
      source=${spec#*:}
      if ! command -v "$bin" >/dev/null 2>&1 &&
        [[ ! -e "$nix_profile_bin_dir/$bin" ]] &&
        [[ ! -e "/run/current-system/sw/bin/$bin" ]]; then
        if [[ $source != *'#'* ]]; then
          source="nixpkgs#$source"
        fi
        missing+=("$source")
      fi
    done

    if ((${#missing[@]})); then
      "$nix_bin" profile install "${missing[@]}"
    else
      printf '%s\n' 'Nix profile tools already installed; checking for upgrades.'
    fi

    "$nix_bin" profile upgrade --all

# Apply chezmoi-managed dotfiles.
[group('setup')]
apply: (doctor 'apply')
    chezmoi init \
      --apply \
      --refresh-externals=auto \
      --source {{ quote(repo_dir) }}

# Preview pending chezmoi-managed dotfile changes without refreshing externals.
[group('setup')]
dotfiles-diff: (doctor 'apply')
    chezmoi \
      --source {{ quote(repo_dir) }} \
      --refresh-externals=never \
      diff

# Apply Helium extensions and settings; quit Helium first so profile writes run.
[group('setup')]
helium: (doctor 'setup')
    ansible/bootstrap.sh --tags helium

[doc('Bootstrap userland, apply dotfiles, then apply host stages.')]
[group('setup')]
setup: (doctor 'setup')
    ansible/bootstrap.sh --setup

# Refresh userland, dotfiles, and host stages on an already-bootstrapped machine.
[group('setup')]
update: _userland apply _host

[private]
_deps:
    install_args=(collection install -r ansible/requirements.yml -p .ansible/collections)
    for collection in community/general community/sops; do
      if [[ ! -f .ansible/collections/ansible_collections/$collection/MANIFEST.json ]]; then
        install_args+=(--force)
        break
      fi
    done
    ansible-galaxy "${install_args[@]}"

[private]
_userland:
    ansible/bootstrap.sh --tags userland

[private]
_host:
    ansible/bootstrap.sh --tags host

# Format the repository through the flake's treefmt wrapper.
[group('dev')]
fmt: (doctor 'fmt') (_format [])

# Rerun a recipe when files change.
[arg('args', help='Recipe and arguments to rerun on file changes')]
[group('dev')]
watch +args=['check']: (doctor 'watch')
    watchexec --clear --restart -- {{ quote(just_executable()) }} --justfile {{ quote(justfile()) }} {{ quote(args) }}

# Run the same treefmt wrapper in CI mode without retaining rewrites.
[group('dev')]
check-format: (doctor 'fmt') (_format ['--', '--ci'])

[private]
_format *args:
    nix fmt {{ quote(args) }}

[parallel]
[private]
_lint-files: _check-worktree-paths _lint-chezmoi-source (_run-files 'jq' ['*.json', 'flake.lock', ':(exclude).vscode/settings.json'] ['empty']) _lint-container-files (_run-files 'luacheck' ['*.lua'] ['--globals', 'Command', 'cx', 'ya', '--']) (_run 'rumdl' ['check', '--respect-gitignore', '--exclude', 'packages/terminal-theme-tools/vendor/**', '.']) _lint-nix npins-check (_run 'uv' ['run', 'ruff', 'check', '.']) _lint-shell-files _lint-shell-templates-portable _lint-templates (_run-files 'taplo' ['*.toml'] ['lint']) _lint-xml

[private]
_lint-container-files:
    [[ {{ quote(host_os) }} == linux ]] || exit 0
    files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] && files+=("$file")
    done < <(git ls-files -z --cached --others --exclude-standard -- Dockerfile Containerfile)
    ((${#files[@]} == 0)) || hadolint "${files[@]}"

[private]
_check-worktree-paths:
    broken=0
    while IFS= read -r -d '' file; do
      if [[ -L $file && ! -e $file ]]; then
        target=$(readlink "$file")
        if [[ $file == bluebuild/files/system/* && $target == /* && -e bluebuild/files/system$target ]]; then
          continue
        fi
        printf 'broken symlink: %s\n' "$file" >&2
        broken=1
      elif [[ ! -e $file ]]; then
        printf 'tracked path missing from worktree: %s\n' "$file" >&2
      fi
    done < <(git ls-files -z --cached --others --exclude-standard --)
    exit "$broken"

[private]
_lint-chezmoi-source: sops-check
    temporary_dir=$(mktemp -d)
    trap 'rm -rf "$temporary_dir"' EXIT
    chezmoi_executable=$(command -v chezmoi)
    render_path=$PATH
    records_age_key_file=${SOPS_AGE_KEY_FILE:-}
    if [[ -z $records_age_key_file && -f $HOME/.config/sops/age/keys.txt ]]; then
      records_age_key_file=$HOME/.config/sops/age/keys.txt
    fi
    managed_source_paths="$temporary_dir/managed-source-paths"
    managed_target_paths="$temporary_dir/managed-target-paths"
    platforms=(
      'darwin|{"chezmoi":{"os":"darwin","arch":"arm64","osRelease":{}}}'
      'fedora|{"chezmoi":{"os":"linux","arch":"amd64","osRelease":{"id":"fedora"}}}'
      'nixos|{"chezmoi":{"os":"linux","arch":"amd64","osRelease":{"id":"nixos"}}}'
      'windows|{"chezmoi":{"os":"windows","arch":"amd64","osRelease":{}}}'
    )
    : > "$managed_source_paths"
    : > "$managed_target_paths"
    invalid=0
    for platform in "${platforms[@]}"; do
      platform_name=${platform%%|*}
      platform_override=${platform#*|}
      destination="$temporary_dir/home-$platform_name"
      platform_config_home="$temporary_dir/config-$platform_name"
      config_file="$platform_config_home/chezmoi/chezmoi.toml"
      persistent_state="$platform_config_home/chezmoi/chezmoi.boltdb"
      render_stderr="$temporary_dir/$platform_name-render-stderr"
      mkdir -p "$destination"
      chezmoi_for_platform() {
        HOME="$destination" \
        DOTFILES_RECORDS_HOST_OS={{ quote(if host_os == "macos" { "darwin" } else { host_os }) }} \
        PATH="$render_path" \
        SOPS_AGE_KEY_FILE="$records_age_key_file" \
        "$chezmoi_executable" \
          --config "$config_file" \
          --destination "$destination" \
          --persistent-state "$persistent_state" \
          --override-data "$platform_override" \
          --no-tty \
          --refresh-externals=never \
          "$@"
      }
      chezmoi_for_platform init --source {{ quote(repo_dir) }}
      chezmoi_for_platform dump-config --format=json | jq -e \
        '.umask == 18
          and .add.secrets == "error"
          and .add.templateSymlinks == true
          and .edit.apply == false
          and .edit.hardlink == true
          and .edit.watch == true' >/dev/null
      chezmoi_for_platform \
        managed --path-style=source-relative >> "$managed_source_paths"
      chezmoi_for_platform managed >> "$managed_target_paths"
      if ! chezmoi_for_platform \
        apply --force --exclude scripts,externals \
        >/dev/null 2> "$render_stderr"; then
        cat "$render_stderr" >&2
        invalid=1
      elif [[ -s $render_stderr ]]; then
        printf 'chezmoi render warning for %s:\n' "$platform_name" >&2
        cat "$render_stderr" >&2
        invalid=1
      elif ! chezmoi_for_platform \
        verify --exclude scripts,externals; then
        printf 'chezmoi verification failed for %s after an isolated apply\n' \
          "$platform_name" >&2
        invalid=1
      fi
    done
    sort -u -o "$managed_source_paths" "$managed_source_paths"
    sort -u -o "$managed_target_paths" "$managed_target_paths"

    source_only_entries=(README.md package.json tsconfig.json)
    for source_entry in "${source_only_entries[@]}"; do
      if grep -Fqx -- "$source_entry" "$managed_target_paths"; then
        printf 'chezmoi manages source-only workspace file: dotfiles/%s\n' \
          "$source_entry" >&2
        invalid=1
      fi
    done

    while IFS= read -r -d '' ignored_source_path; do
      source_entry=${ignored_source_path#dotfiles/}
      source_entry=${source_entry%/}
      if grep -Fqx -- "$source_entry" "$managed_source_paths"; then
        printf 'chezmoi manages Git-ignored source artifact: %s\n' \
          "$ignored_source_path" >&2
        invalid=1
      fi
    done < <(
      git ls-files \
        --others \
        --ignored \
        --exclude-standard \
        --directory \
        --no-empty-directory \
        -z \
        -- dotfiles
    )

    exit "$invalid"

[private]
_lint-nix:
    nix_files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] && nix_files+=("$file")
    done < <(git ls-files -z --cached --others --exclude-standard -- '*.nix')
    deadnix_files=()
    for file in "${nix_files[@]}"; do
      nix-instantiate --parse "$file" >/dev/null
      case $file in
        hosts/linux/hardware-configuration.nix | packages/hyper-window-tiling/bun.nix | packages/terminal-theme-tools/zig-pkg/*) ;;
        *) deadnix_files+=("$file") ;;
      esac
    done
    ((${#deadnix_files[@]} == 0)) || deadnix --fail "${deadnix_files[@]}"
    statix check .

[private]
_lint-xml:
    xml_files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] && xml_files+=("$file")
    done < <(git ls-files -z --cached --others --exclude-standard -- '*.plist' '*.xml')
    ((${#xml_files[@]} == 0)) || uv run python -c \
      'import sys; from defusedxml.ElementTree import parse; [parse(path) for path in sys.argv[1:]]' \
      "${xml_files[@]}"

[private]
_lint-templates:
    python_template_files=()
    ruby_template_files=()
    json_template_files=()
    toml_template_files=()
    xml_template_files=()
    bash_template_files=()
    zsh_template_files=()
    python_input_template_files=()
    xml_input_template_files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] || continue
      case "$file" in
        dotfiles/.chezmoitemplates/*) ;;
        dotfiles/dot_bash*.tmpl | *.bash.tmpl | *.sh.tmpl) bash_template_files+=("$file") ;;
        dotfiles/dot_zsh*.tmpl | *.zsh.tmpl) zsh_template_files+=("$file") ;;
        *.py.tmpl) python_template_files+=("$file") ;;
        *.rb.tmpl) ruby_template_files+=("$file") ;;
        *.json.tmpl) json_template_files+=("$file") ;;
        *.toml.tmpl) toml_template_files+=("$file") ;;
        *.plist.tmpl | *.xml.tmpl | *.tmTheme.tmpl) xml_template_files+=("$file") ;;
        *.py.in) python_input_template_files+=("$file") ;;
        *.plist.in | *.xml.in) xml_input_template_files+=("$file") ;;
      esac
    done < <(git ls-files -z --cached --others --exclude-standard -- '*.tmpl' '*.py.in' '*.plist.in' '*.xml.in')

    tmp_destination=$(mktemp -d)
    trap 'rm -rf "$tmp_destination"' EXIT
    chezmoi apply \
      --dry-run \
      --source {{ quote(repo_dir) }} \
      --destination "$tmp_destination" \
      --force \
      --no-tty \
      --refresh-externals=never >/dev/null

    for file in \
      "${bash_template_files[@]}" \
      "${zsh_template_files[@]}"; do
      rendered_file="$tmp_destination/rendered-templates/${file%.tmpl}"
      mkdir -p "${rendered_file%/*}"
      chezmoi --source {{ quote(repo_dir) }} execute-template < "$file" > "$rendered_file"
    done
    script_platform_overrides=(
      '{"chezmoi":{"os":"darwin","arch":"arm64","osRelease":{}}}'
      '{"chezmoi":{"os":"linux","arch":"amd64","osRelease":{"id":"fedora"}}}'
    )
    rendered_python_files=()
    rendered_ruby_files=()
    rendered_json_files=()
    rendered_toml_files=()
    rendered_xml_template_files=()
    platform_index=0
    for platform_override in "${script_platform_overrides[@]}"; do
      platform_index=$((platform_index + 1))
      for file in \
        "${python_template_files[@]}" \
        "${ruby_template_files[@]}" \
        "${json_template_files[@]}" \
        "${toml_template_files[@]}" \
        "${xml_template_files[@]}"; do
        rendered_file="$tmp_destination/rendered-script-templates/$platform_index/${file%.tmpl}"
        mkdir -p "${rendered_file%/*}"
        chezmoi --source {{ quote(repo_dir) }} \
          --override-data "$platform_override" \
          execute-template < "$file" > "$rendered_file"
        [[ -s $rendered_file ]] || continue
        case "$file" in
          *.py.tmpl) rendered_python_files+=("$rendered_file|${file%.tmpl}") ;;
          *.rb.tmpl) rendered_ruby_files+=("$rendered_file") ;;
          *.json.tmpl) rendered_json_files+=("$rendered_file") ;;
          *.toml.tmpl) rendered_toml_files+=("$rendered_file") ;;
          *.plist.tmpl | *.xml.tmpl | *.tmTheme.tmpl)
            rendered_xml_template_files+=("$rendered_file")
            ;;
        esac
      done
    done
    if ((${#rendered_python_files[@]} > 0)); then
      PYTHONPYCACHEPREFIX="$tmp_destination/pycache" \
        uv run python -m compileall -q "$tmp_destination/rendered-script-templates"
      for rendered_python in "${rendered_python_files[@]}"; do
        rendered_file=${rendered_python%%|*}
        source_file=${rendered_python#*|}
        uv run ruff check --stdin-filename "$source_file" - < "$rendered_file"
      done
    fi
    for rendered_file in "${rendered_ruby_files[@]}"; do
      ruby -c "$rendered_file" >/dev/null
    done
    for rendered_file in "${rendered_json_files[@]}"; do
      jq empty "$rendered_file"
    done
    for rendered_file in "${rendered_toml_files[@]}"; do
      if ! taplo_output=$(taplo lint "$rendered_file" 2>&1); then
        printf 'invalid rendered TOML: %s\n%s\n' "$rendered_file" "$taplo_output" >&2
        exit 1
      fi
    done
    ((${#rendered_xml_template_files[@]} == 0)) || uv run python -c \
      'import sys; from defusedxml.ElementTree import parse; [parse(path) for path in sys.argv[1:]]' \
      "${rendered_xml_template_files[@]}"
    for file in "${bash_template_files[@]}"; do
      rendered_file="$tmp_destination/rendered-templates/${file%.tmpl}"
      bash -n "$rendered_file"
      # Cached integrations are generated by their upstream tools. Syntax-check
      # them, but reserve ShellCheck policy for shell code maintained here.
      case "$file" in
        dotfiles/dot_cache/*) continue ;;
      esac
      shellcheck -x --shell=bash "$rendered_file"
    done
    for file in "${zsh_template_files[@]}"; do
      zsh -n "$tmp_destination/rendered-templates/${file%.tmpl}"
    done
    for file in "${python_input_template_files[@]}"; do
      rendered_file="$tmp_destination/rendered-input-templates/${file%.in}"
      mkdir -p "${rendered_file%/*}"
      sed -E 's/@[A-Za-z_][A-Za-z0-9_]*@/template_value/g' "$file" > "$rendered_file"
    done
    if ((${#python_input_template_files[@]} > 0)); then
      PYTHONPYCACHEPREFIX="$tmp_destination/pycache" \
        uv run python -m compileall -q "$tmp_destination/rendered-input-templates"
    fi
    rendered_xml_files=()
    for file in "${xml_input_template_files[@]}"; do
      rendered_file="$tmp_destination/rendered-input-templates/${file%.in}"
      mkdir -p "${rendered_file%/*}"
      sed -E 's/@[A-Za-z_][A-Za-z0-9_]*@/template_value/g' "$file" > "$rendered_file"
      rendered_xml_files+=("$rendered_file")
    done
    ((${#rendered_xml_files[@]} == 0)) || uv run python -c \
      'import sys; from defusedxml.ElementTree import parse; [parse(path) for path in sys.argv[1:]]' \
      "${rendered_xml_files[@]}"

[private]
_lint-shell-templates-portable:
    platform_overrides=(
      '{"chezmoi":{"os":"darwin","arch":"arm64","osRelease":{}}}'
      '{"chezmoi":{"os":"linux","arch":"amd64","osRelease":{"id":"fedora"}}}'
      '{"chezmoi":{"os":"linux","arch":"amd64","osRelease":{"id":"nixos"}}}'
    )
    shell_template_files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] && shell_template_files+=("$file")
    done < <(
      git ls-files -z --cached --others --exclude-standard -- \
        'dotfiles/dot_bash*.tmpl' \
        'dotfiles/dot_zsh*.tmpl' \
        'dotfiles/dot_config/shell/*.tmpl' \
        'dotfiles/dot_config/shell/exact_bashrc.d/*.tmpl' \
        'dotfiles/dot_config/shell/exact_interactive.d/*.tmpl' \
        'dotfiles/dot_config/shell/exact_zshrc.d/*.tmpl'
    )

    tmp_destination=$(mktemp -d)
    trap 'rm -rf "$tmp_destination"' EXIT
    platform_index=0
    for platform_override in "${platform_overrides[@]}"; do
      platform_index=$((platform_index + 1))
      for file in "${shell_template_files[@]}"; do
        rendered_file="$tmp_destination/$platform_index/${file%.tmpl}"
        mkdir -p "${rendered_file%/*}"
        chezmoi --source {{ quote(repo_dir) }} \
          --override-data "$platform_override" \
          execute-template < "$file" > "$rendered_file"
        case "$file" in
          dotfiles/dot_bash*.tmpl | *.bash.tmpl)
            bash -n "$rendered_file"
            shellcheck -x --shell=bash "$rendered_file"
            ;;
          dotfiles/dot_zsh*.tmpl | *.zsh.tmpl)
            zsh -n "$rendered_file"
            ;;
          *.sh.tmpl)
            bash -n "$rendered_file"
            zsh -n "$rendered_file"
            shellcheck -x --shell=bash "$rendered_file"
            ;;
        esac
      done
    done

[private]
_lint-shell-files:
    shell_files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] || continue
      case "$file" in
        *.tmpl | *.txt | *.patch) continue ;;
        *.sh | *.sh.in | *.bash) shell_files+=("$file"); continue ;;
      esac
      if head -n 2 < "$file" | grep -Eq '^#!.*[[:space:]/](sh|bash)([[:space:]]|$)|^# shellcheck shell=(sh|bash)'; then
        shell_files+=("$file")
      fi
    done < <(git ls-files -z --cached --others --exclude-standard --)
    ((${#shell_files[@]} == 0)) && exit
    shellcheck -x "${shell_files[@]}"

[private]
_run executable +arguments:
    printf '==> %s\n' {{ quote(join_list([executable, arguments])) }}
    {{ quote(require(executable)) }} {{ quote(arguments) }}

[private]
_run-files executable patterns arguments=[]:
    printf '==> %s\n' {{ quote(join_list([executable, arguments])) }}
    if (({{ len(patterns) }} == 0)); then
      {{ quote(require(executable)) }} {{ quote(arguments) }}
      exit
    fi
    files=()
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] && files+=("$file")
    done < <(git ls-files -z --cached --others --exclude-standard -- {{ quote(patterns) }})
    ((${#files[@]} == 0)) || {{ quote(require(executable)) }} {{ quote(arguments) }} "${files[@]}"

[private]
_check-python: python-complexity python-dead-code python-dependencies python-typecheck python-test
    uv lock --check
    uv sync --check
    bytecode_dir=$(mktemp -d)
    build_dir=$(mktemp -d)
    trap 'rm -rf "$bytecode_dir" "$build_dir"' EXIT
    PYTHONPYCACHEPREFIX="$bytecode_dir" uv run python -m compileall -q ansible dotfiles packages
    uv build --out-dir "$build_dir" --no-build-logs

# Update every non-frozen npins source.
[group('dev')]
source-update:
    nix shell nixpkgs#npins --command bash .github/renovate/update-npins-lock.sh
    bash bluebuild/recipes/spectrum/sync-sources.sh

# Verify that npins metadata and fetch URLs describe the same sources.
[group('dev')]
npins-check:
    bash .github/renovate/check-npins.sh

# Refresh each patch in temporary copies and compare it with the checked-in
# queue at the exact source revision used by package builds.
[arg('package', pattern=['all', 'ghostty-patched', 'jj-patched', 'kanata-with-cmd'])]
[group('dev')]
quilt-check package='all':
    packages/quilt.sh check {{ quote(package) }}

# Open a disposable, writable copy of a package's pinned source with its whole
# Quilt queue applied. Patch refreshes are written directly to this repository.
[arg('package', pattern=['ghostty-patched', 'jj-patched', 'kanata-with-cmd'])]
[group('dev')]
quilt-shell package:
    packages/quilt.sh shell {{ quote(package) }}

# Check declared dependencies against first-party imports.
[group('dev')]
python-dependencies:
    uv run deptry .

# Run the Python test suite.
[group('dev')]
python-test *args:
    uv run pytest {{ quote(args) }}

# Type-check the Python source roots configured in pyproject.toml.
[group('dev')]
python-typecheck *args:
    uv run ty check {{ quote(args) }}

# Scan the first-party Python source roots configured in pyproject.toml.
[group('dev')]
python-dead-code:
    uv run vulture

# Reject cognitively complex functions in the configured Python source roots.
[group('dev')]
python-complexity:
    uv run complexipy --plain

[private]
_check-zig: (doctor 'zig')
    zig fmt --check build.zig packages/terminal-theme-tools/build.zig packages/terminal-theme-tools/build_support.zig packages/terminal-theme-tools/src/*.zig
    zig build test
    zig build --release=small

[private]
_check-ansible: (doctor 'ansible') _deps
    ansible-playbook --syntax-check ansible/site.yml
    ansible-lint ansible
    yamllint .

[private]
_check-github-actions:
    actionlint
    zizmor --persona=pedantic .github/workflows .github/actions

[private]
_check-bun: (doctor 'bun')
    bun run check

# Verify bun2nix's dependency expression matches the independently packaged
# Hyper Window Tiling extension's Bun lockfile.
[group('check')]
bun-nix-check:
    generated=$(nix run .#bun2nix -- \
      --lock-file packages/hyper-window-tiling/bun.lock \
      --copy-prefix packages/hyper-window-tiling)
    if ! diff -u \
      packages/hyper-window-tiling/bun.nix \
      <(printf '%s\n' "$generated"); then
      printf 'packages/hyper-window-tiling/bun.nix is stale; run `just bun-nix-update`.\n' >&2
      exit 1
    fi

# Regenerate bun2nix's dependency expression for the independently packaged
# Hyper Window Tiling extension after its Bun lockfile changes.
[group('dev')]
bun-nix-update:
    nix run .#bun2nix -- \
      --lock-file packages/hyper-window-tiling/bun.lock \
      --copy-prefix packages/hyper-window-tiling \
      --output-file packages/hyper-window-tiling/bun.nix
    nix fmt -- packages/hyper-window-tiling/bun.nix

[private]
_check-ruby:
    bundle exec rubocop
    while IFS= read -r -d '' file; do
      [[ -f $file && ! -L $file ]] || continue
      ruby -c "$file" >/dev/null
    done < <(git ls-files -z --cached --others --exclude-standard -- '*.rb' Brewfile Gemfile)
    bundle exec ruby -Itest test/ruby_tools_test.rb

# Lint repository source files and run project validation.
[private]
_lint-deps:
    bundle install
    bun install --frozen-lockfile
    bun install --cwd packages/hyper-window-tiling --frozen-lockfile

[group('dev')]
lint: (doctor 'lint') check-format _lint-deps _check-ansible _lint-checks

[parallel]
[private]
_lint-checks: _lint-files _check-python _check-zig _check-github-actions _check-bun _check-ruby (quilt-check 'all')

# Evaluate every flake output without building package or test derivations.
[group('dev')]
nix-check: (doctor 'fmt')
    nix store add-path nix/dev >/dev/null
    nix store add-path nix/nixos >/dev/null
    nix flake check --all-systems --keep-going --no-build --no-eval-cache

# Run the repo validation suite.
[group('dev')]
check: lint nix-check
