def nix-build-file [
    file: string,
    args: string = "{}"
] {
    nix-build -E $"with import <nixpkgs> {}; callPackage ($file | path expand) ($args)"
}

def clean-roots [] {
    nix-store --gc --print-roots
    | lines
    | where { |line| $line !~ '^(/nix/var|/run/\w+-system|\{|/proc)' }
    | where { |line| $line !~ '\b(home-manager|flake-registry\.json)\b' }
    | parse --regex '^(?P<path>\S+)'
    | get path
    | each { |path| ^unlink $path }
}

def now [] { date now | format date "%H:%M:%S" }
def nowdate [] { date now | format date "%d-%m-%Y" }
def nowunix [] { date now | format date "%s" }
def xdg-data-dirs [] { echo $env.XDG_DATA_DIRS | str replace -a : "\n" | lines | enumerate }
