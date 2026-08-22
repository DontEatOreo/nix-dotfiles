# frozen_string_literal: true

require "json"

class GhosttyPatched < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  ghostty = pins.fetch("ghostty")
  archive = pins.fetch("ghostty_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Fast, native terminal emulator with dotfiles scrollback patches"
  homepage "https://ghostty.org"
  url archive.fetch("url")
  version "1.3.2-dev.#{ghostty.fetch("revision")[0, 7]}"
  sha256 digest
  license "MIT"

  depends_on "gettext" => :build
  depends_on xcode: :build
  depends_on "zig" => :build
  depends_on :macos

  def install
    patch_dir = Pathname(__dir__).parent/"packages/ghostty-patched/patches"
    patches = (patch_dir/"series").readlines(chomp: true).map { |name| patch_dir/name }
    odie "Ghostty patch series is empty: #{patch_dir}" if patches.empty?

    system "git", "apply", *patches
    system formula_opt_bin("zig")/"zig", "build",
           "-Doptimize=ReleaseFast",
           "-Demit-test-exe=false",
           "-Dxcframework-target=native",
           "-Dversion-string=#{version}"

    prefix.install "zig-out/Ghostty.app"
  end

  def caveats
    <<~CAVEATS
      Ghostty.app is installed at:
        #{opt_prefix}/Ghostty.app

      The dotfiles Ansible role copies it into /Applications so launchers can
      discover the application bundle.
    CAVEATS
  end

  test do
    output = shell_output("#{prefix}/Ghostty.app/Contents/MacOS/ghostty +version")
    assert_match version.to_s, output
  end
end
