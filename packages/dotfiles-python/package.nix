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
      (repositoryRoot + /pyproject.toml)
      (repositoryRoot + /dotfiles/.chezmoitemplates/black_rose_doll_palette.json)
      (packageRoot + /assets)
      (packageRoot + /src/workstation)
    ];
  };

  build-system = [ python314Packages.setuptools ];
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
  doCheck = false;
  doInstallCheck = false;

  meta = {
    description = "Personal workstation utilities shared across Linux and macOS";
    mainProgram = "phone-mirror";
    platforms = lib.platforms.unix;
  };
}
