def nix-build-file [
    file: string,
    args: string = "{}"
] {
    nix-build -E $"with import <nixpkgs> {}; callPackage ($file | path expand) ($args)"
}

def clean-roots [] {
    let $paths_to_delete = (nix-store --gc --print-roots
        | lines
        | where { |line| $line !~ '^(/nix/var|/run/\w+-system|\{|/proc)' }
        | where { |line| $line !~ '\b(home-manager|flake-registry\.json)\b' }
        | parse --regex '^(?P<path>\S+)'
        | get path)

    if ($paths_to_delete | is-empty) {
        print "Nothing to clean"
        return
    }

    print "Cleaning roots..."
    let $results = for $path in $paths_to_delete {
        try {
            ^unlink $path
            { path: $path, status: "Deleted" }
        } catch { |e|
            { path: $path, status: $"Error: `($e.msg)`" }
        }
    }

    if not ($results | is-empty) {
        $results | table
    }
    print "Done"
}

def now [] { date now | format date "%H:%M:%S" }
def nowdate [] { date now | format date "%d-%m-%Y" }
def nowunix [] { date now | format date "%s" }
def xdg-data-dirs [] { echo $env.XDG_DATA_DIRS | str replace -a : "\n" | lines | enumerate }
