# theme-run

`theme-run` detects whether the terminal uses a dark or light theme, then runs
a matching application profile. Profiles can add command arguments, set
environment variables, or create a temporary themed configuration file.

The implementation is pure Go. It builds with `CGO_ENABLED=0` and uses a
strict TOML manifest without a C library or public C interface.

## Build

Run these commands from this directory:

```console
go build ./cmd/theme-run
go test ./...
```

## Usage

```text
theme-run [--help|--version|--print-theme|--print-theme-no-terminal] [--] COMMAND [ARG...]
```

Unknown commands are executed unchanged. A matching runner can resolve a
different executable, apply default arguments and environment changes, and
select an integration for the detected theme.

The default user manifest is `$XDG_CONFIG_HOME/theme-run/config.toml`, falling
back to `~/.config/theme-run/config.toml`. `THEME_RUN_CONFIG` can contain a
path-separated list of manifest fragments. Later fragments replace runners,
integrations, and interpreters with the same name.

Theme detection checks configured environment variables first. It can then
query `/dev/tty` with Kitty's color-scheme protocol or OSC 11, followed by the
configured desktop helpers and platform fallback.
