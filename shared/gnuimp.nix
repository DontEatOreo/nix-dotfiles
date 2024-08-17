# GNU Implementations of certain programs
# The rationale behind using a "GNU" implementation instead of the
# system one is that, for example, on macOS, awk and grep
# BSD implementations miss certain options, making it more cumbersome
# to use them compared to their GNU counterpart
{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      gawk
      gnugrep
      gnupatch
      gnused
      gnutar
      ;
  };
}
