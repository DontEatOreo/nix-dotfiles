def nix-complete [context: string, offset: int] {
    # Extract command parts from context
    let cmd_parts = ($context | str trim | split row " ")
    
    # Get arguments excluding "nix" itself
    let nix_args = if ($cmd_parts | length) > 1 { 
        $cmd_parts | skip 1 
    } else { 
        [] 
    }
    
    # Nix expects the argument index to complete
    let arg_count = ($nix_args | length)
    
    # Call nix with NIX_GET_COMPLETIONS environment variable
    let completions = (do {
        with-env [NIX_GET_COMPLETIONS $arg_count] {
            ^nix ...$nix_args "" 2>/dev/null | complete | get stdout
        }
    } | default "")
    
    if ($completions | is-empty) {
        return []
    }
    
    let lines = ($completions | lines | where { |line| ($line | str trim) != "" })
    
    # The first line indicates whether filenames should be completed
    # Skip it and process the actual completion entries
    if ($lines | length) > 1 {
        $lines 
        | skip 1 
        | each { |line| 
            let parts = ($line | split row "\t")
            let value = ($parts | get 0)
            let description = if ($parts | length) > 1 { 
                $parts | get 1 
            } else { 
                "" 
            }
            {
                value: $value,
                description: $description
            }
        }
    } else {
        []
    }
}

def nix [
    --help(-h)                      # Show help message
    --version                       # Show version information
    ...args: string@nix-complete    # Nix subcommands and arguments
] {
    ^nix ...$args
}
