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
      (repositoryRoot + /ansible/plugins/filter/dotfiles.py)
      (repositoryRoot + /ansible/library/dotfiles_codesign.py)
      (repositoryRoot + /ansible/library/dotfiles_selinux_service.py)
      (repositoryRoot + /ansible/roles/system/files/kmscon/kmscon-refresh.py)
      (repositoryRoot + /ansible/roles/system/files/kmscon/kmscon-theme-config.py)
      (repositoryRoot + /ansible/roles/system/files/rustdesk-selinux/rustdesk.fc)
      (repositoryRoot + /ansible/roles/system/files/rustdesk-selinux/rustdesk.te)
      (repositoryRoot + /ansible/roles/system/tasks/rustdesk.yml)
      (repositoryRoot + /bluebuild/recipes/spectrum.yml)
      (repositoryRoot + /pyproject.toml)
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

  doCheck = true;
  doInstallCheck = false;

  meta = {
    description = "Personal workstation utilities shared across Linux and macOS";
    mainProgram = "phone-mirror";
    platforms = lib.platforms.unix;
  };
}
