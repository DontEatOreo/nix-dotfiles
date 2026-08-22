# frozen_string_literal: true

require "json"

class JjPatched < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  jj = pins.fetch("jj")
  archive = pins.fetch("jj_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Jujutsu build with native signing, redate, and shallow workflow patches"
  homepage "https://github.com/jj-vcs/jj"
  url archive.fetch("url")
  version "0.44.0-head-#{jj.fetch("revision")[0, 8]}"
  sha256 digest
  # The patch queue can change without moving the pinned upstream revision.
  # Bump this whenever the queue changes so Homebrew upgrades installed builds.
  license "Apache-2.0"
  revision 1
  depends_on "rust" => :build

  conflicts_with "jj", because: "both install a jj binary"

  def install
    tap_root = Pathname(__dir__).parent
    patch_dir = tap_root/"packages/jj-patched/patches"
    patches = (patch_dir/"series").readlines(chomp: true).map { |name| patch_dir/name }
    odie "jj patch series is empty: #{patch_dir}" if patches.empty?

    system "git", "apply", *patches
    # Cargo install does not build test targets; select the one shipped binary
    # so future auxiliary binaries do not lengthen this patched source build.
    system "cargo", "install", "--bin", "jj", *std_cargo_args(path: "cli")

    generate_completions_from_executable(bin/"jj", shell_parameter_format: :clap)
    system bin/"jj", "util", "install-man-pages", man
  end
end
