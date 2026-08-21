{
  lib,
  python314Packages,
  stdenv,
}:
let
  repositoryRoot = ../..;
  packageRoot = ./.;
in
python314Packages.buildPythonApplication {
  pname = "dotfiles-python";
  version = "0.1.0";
  pyproject = true;
  strictDeps = true;

  src = lib.fileset.toSource {
    root = repositoryRoot;
    fileset = lib.fileset.unions [
      (repositoryRoot + /Justfile)
      (repositoryRoot + /ansible/bootstrap.sh)
      (repositoryRoot + /ansible/requirements.yml)
      (repositoryRoot + /ansible/site.yml)
      (repositoryRoot + /ansible/library/dotfiles_codesign.py)
      (repositoryRoot + /ansible/library/dotfiles_selinux_service.py)
      (repositoryRoot + /ansible/roles/keyboard/files/toshy/merge-slices.py)
      (repositoryRoot + /ansible/roles/keyboard/files/toshy/setup.py)
      (repositoryRoot + /ansible/roles/system/files/kmscon/kmscon-refresh.py)
      (repositoryRoot + /ansible/roles/system/files/kmscon/kmscon-theme-config.py)
      (repositoryRoot + /ansible/roles/system/files/rustdesk-selinux/rustdesk.fc)
      (repositoryRoot + /ansible/roles/system/files/rustdesk-selinux/rustdesk.te)
      (repositoryRoot + /ansible/roles/system/tasks/rustdesk.yml)
      (repositoryRoot + /bluebuild/recipes/spectrum.yml)
      (repositoryRoot + /dotfiles/dot_local/bin/executable_sops-age-key-1password)
      (repositoryRoot + /pyproject.toml)
      (repositoryRoot + /secrets/secrets.yaml)
      (repositoryRoot + /ansible/tests)
      (repositoryRoot + /dotfiles/.chezmoitemplates/black_rose_doll_palette.json)
      (packageRoot + /assets)
      (packageRoot + /src/workstation)
      (packageRoot + /tests)
    ];
  };

  build-system = [ python314Packages.setuptools ];
  nativeCheckInputs = [
    python314Packages.astral
    python314Packages.pytestCheckHook
  ];

  dependencies =
    (with python314Packages; [
      cyclopts
      packaging
      platformdirs
      psutil
      pydantic
      pydantic-settings
      rich
    ])
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      python314Packages.pyobjc-framework-Cocoa
    ];

  pythonImportsCheck = [ "workstation" ];
  pytestFlags = [
    "ansible/tests"
    "packages/dotfiles-python/tests"
  ];
  # This repository-wide policy test intentionally shells out to Git in a
  # checkout. The Python workflow runs it there; a filtered Nix source has no
  # .git directory and should test only its declared package inputs.
  disabledTests = [ "test_every_bash_script_declares_its_shellcheck_dialect" ];

  doCheck = true;
  doInstallCheck = false;

  meta = {
    description = "Personal workstation utilities shared across Linux and macOS";
    mainProgram = "phone-mirror";
    platforms = lib.platforms.unix;
  };
}
