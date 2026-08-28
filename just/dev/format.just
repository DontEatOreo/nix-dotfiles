# Format the repository through the flake's treefmt wrapper.
[group('dev')]
fmt: (doctor 'fmt') (_format [])

# Rerun a recipe when files change.
[arg('args', help='Recipe and arguments to rerun on file changes')]
[group('dev')]
watch +args=['check']: (doctor 'watch')
    watchexec --clear --restart -- {{ quote(just_executable()) }} --justfile {{ quote(justfile()) }} {{ quote(args) }}

# Run the same treefmt wrapper in CI mode without retaining rewrites.
[group('check')]
check-format: (doctor 'fmt') (_format ['--', '--ci'])

[private]
_format *args:
    nix fmt {{ quote(args) }}
