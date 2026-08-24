# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=error=true

ARG FEDORA_VERSION=45@sha256:7791538bb091b82097f1aef71ec64b2154f886716f6f0b822dc839bb3c74c0aa
FROM ghcr.io/astral-sh/uv:0.12.5@sha256:e85be844203885286c60ffad8a858d48afb6c5a5c237ca0e67f12e74b8f174b1 AS uv

FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS dotfiles-base

ARG TARGETPLATFORM
ARG TEST_USER=dotfiles
ARG TEST_UID=1000
ARG TEST_GID=1000
ARG TEST_HOME=/home/dotfiles

# Keep this smoke-test Dockerfile on Podman/Buildah-compatible syntax. The local
# Compose workflow uses Podman, whose imagebuilder rejects BuildKit conveniences
# like COPY --link and heredoc RUN blocks.
COPY containers/fedora-smoke-test-packages.txt /tmp/fedora-smoke-test-packages.txt
# hadolint ignore=DL3041
RUN --mount=type=cache,id=dotfiles-dnf4-${TARGETPLATFORM},sharing=locked,target=/var/cache/dnf \
    --mount=type=cache,id=dotfiles-dnf5-${TARGETPLATFORM},sharing=locked,target=/var/cache/libdnf5 \
    set -eu; \
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' /tmp/fedora-smoke-test-packages.txt \
      > /tmp/fedora-smoke-test-packages.filtered.txt; \
    xargs -r dnf install -y --setopt=install_weak_deps=False \
      < /tmp/fedora-smoke-test-packages.filtered.txt; \
    rm -f /tmp/fedora-smoke-test-packages.txt /tmp/fedora-smoke-test-packages.filtered.txt

RUN set -eu; \
    mkdir -p "$(dirname "${TEST_HOME}")"; \
    groupadd --gid "${TEST_GID}" "${TEST_USER}"; \
    useradd \
      --uid "${TEST_UID}" \
      --gid "${TEST_GID}" \
      --create-home \
      --home-dir "${TEST_HOME}" \
      --no-log-init \
      "${TEST_USER}"; \
    install -d -o "${TEST_UID}" -g "${TEST_GID}" /workspace/dotfiles

ENV HOME=${TEST_HOME}
ENV XDG_CACHE_HOME=${TEST_HOME}/.cache
ENV TMPDIR=${TEST_HOME}/.cache/tmp
ENV TMP=${TEST_HOME}/.cache/tmp
ENV TEMP=${TEST_HOME}/.cache/tmp
ENV PATH=${TEST_HOME}/.local/bin:${TEST_HOME}/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV DOTFILES_PROCESS_CAPTURE_TIMEOUT_SECS=180

COPY --from=uv /uv /usr/local/bin/uv

WORKDIR /workspace/dotfiles
USER ${TEST_UID}:${TEST_GID}

RUN mkdir -p "${TMPDIR}" "${HOME}/.local/bin"

# Keep the focused tool playbook independent from unrelated Ansible roles.
FROM dotfiles-base AS tool-build-base

COPY --chown=${TEST_UID}:${TEST_GID} ansible.cfg ./
COPY --chown=${TEST_UID}:${TEST_GID} ansible/inventory/ ansible/inventory/
COPY --chown=${TEST_UID}:${TEST_GID} ansible/roles/platform/ ansible/roles/platform/
COPY --chown=${TEST_UID}:${TEST_GID} containers/fedora-smoke-test.yml containers/fedora-smoke-test.yml

# Build Python and Zig artifacts in independent stages. Changes to one toolchain
# cannot invalidate the other, and mode=max external caches retain both branches.
FROM tool-build-base AS python-tool-build

COPY --chown=${TEST_UID}:${TEST_GID} ansible/roles/bootstrap/tasks/python-tool.yml ansible/roles/bootstrap/tasks/python-tool.yml
COPY --chown=${TEST_UID}:${TEST_GID} ansible/roles/tools/tasks/python.yml ansible/roles/tools/tasks/python.yml
COPY --chown=${TEST_UID}:${TEST_GID} pyproject.toml uv.lock ./
COPY --chown=${TEST_UID}:${TEST_GID} packages/dotfiles-python/ packages/dotfiles-python/

RUN --mount=type=cache,id=dotfiles-uv-${TARGETPLATFORM},sharing=shared,target=/tmp/dotfiles-uv-cache,uid=${TEST_UID},gid=${TEST_GID} \
    set -eu; \
    export ANSIBLE_BECOME_ASK_PASS=false; \
    export UV_CACHE_DIR=/tmp/dotfiles-uv-cache; \
    ansible-playbook containers/fedora-smoke-test.yml --tags python

FROM tool-build-base AS zig-tool-build

COPY --chown=${TEST_UID}:${TEST_GID} packages/terminal-theme-tools/ packages/terminal-theme-tools/
WORKDIR /workspace/dotfiles/packages/terminal-theme-tools

# Zig's caches provide their own inter-process locking. Keep its global,
# project-local, and package caches distinct so they can be reused independently.
RUN mkdir -p .zig-cache zig-pkg

RUN --mount=type=cache,id=dotfiles-zig-global-${TARGETPLATFORM},sharing=shared,target=/tmp/dotfiles-zig-cache,uid=${TEST_UID},gid=${TEST_GID} \
    --mount=type=cache,id=dotfiles-zig-local-${TARGETPLATFORM},sharing=shared,target=/workspace/dotfiles/packages/terminal-theme-tools/.zig-cache,uid=${TEST_UID},gid=${TEST_GID} \
    --mount=type=cache,id=dotfiles-zig-packages-${TARGETPLATFORM},sharing=shared,target=/workspace/dotfiles/packages/terminal-theme-tools/zig-pkg,uid=${TEST_UID},gid=${TEST_GID} \
    set -eu; \
    export ZIG_GLOBAL_CACHE_DIR=/tmp/dotfiles-zig-cache; \
    zig build --release=small --prefix "${HOME}/.local"

FROM tool-build-base AS dotfiles-test

COPY --from=python-tool-build --chown=${TEST_UID}:${TEST_GID} ${TEST_HOME}/.local/ ${TEST_HOME}/.local/
COPY --from=zig-tool-build --chown=${TEST_UID}:${TEST_GID} ${TEST_HOME}/.local/ ${TEST_HOME}/.local/

# Full-repository validation comes after tool assembly, so lint-only changes do
# not invalidate downloads or compiled artifacts.
COPY --chown=${TEST_UID}:${TEST_GID} ansible/requirements.yml /tmp/ansible-requirements.yml
RUN set -eu; \
    ansible-galaxy collection install \
      -r /tmp/ansible-requirements.yml \
      -p "${HOME}/.ansible/collections"; \
    rm -f /tmp/ansible-requirements.yml

COPY --chown=${TEST_UID}:${TEST_GID} ansible/roles/tools/defaults/ ansible/roles/tools/defaults/
COPY --chown=${TEST_UID}:${TEST_GID} ansible/roles/tools/tasks/verify.yml ansible/roles/tools/tasks/verify.yml
COPY --chown=${TEST_UID}:${TEST_GID} npins/sources.json npins/sources.json
COPY --chown=${TEST_UID}:${TEST_GID} .ansible-lint .yamllint ./
COPY --chown=${TEST_UID}:${TEST_GID} ansible/ ansible/
RUN set -eu; \
    ansible-playbook --syntax-check ansible/site.yml; \
    ansible-lint ansible

COPY --chown=${TEST_UID}:${TEST_GID} . .
RUN set -eu; \
    export ANSIBLE_BECOME_ASK_PASS=false; \
    ansible-playbook containers/fedora-smoke-test.yml --tags verify; \
    yamllint .

RUN set -eu; \
    chezmoi_targets=" \
      .zshrc \
      .bashrc \
      .gitconfig \
      .gitignore_global \
      .ssh/config \
      .ssh/allowed_signers \
      .cache/starship \
      .config \
      .local/share/applications \
    "; \
    set --; \
    for target in ${chezmoi_targets}; do \
      set -- "$@" "${HOME}/${target}"; \
    done; \
    chezmoi \
      --source=/workspace/dotfiles/dotfiles \
      --destination="${HOME}" \
      apply \
      --force \
      --no-tty \
      --parent-dirs \
      --exclude=scripts \
      "$@"

COPY --chmod=0755 containers/fedora-smoke-test.sh /usr/local/bin/dotfiles-smoke-test

RUN dotfiles-smoke-test

CMD ["dotfiles-smoke-test"]
