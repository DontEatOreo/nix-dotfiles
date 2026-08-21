# frozen_string_literal: true

require "json"

class KanataWithCmd < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  upstream = pins.fetch("kanata")
  homebrew = pins.fetch("kanata_homebrew")
  archive = pins.fetch("kanata_homebrew_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Cross-platform keyboard remapper with command actions enabled"
  homepage "https://github.com/#{upstream.dig("repository", "owner")}/#{upstream.dig("repository", "repo")}"
  url archive.fetch("url")
  version "git-#{homebrew.fetch("revision")[0, 7]}"
  sha256 digest
  license "LGPL-3.0-only"
  revision 1
  head "https://github.com/#{homebrew.dig("repository", "owner")}/" \
       "#{homebrew.dig("repository", "repo")}.git",
       branch: homebrew.fetch("branch")

  depends_on "rust" => :build

  conflicts_with "kanata", because: "both install a kanata binary"

  def install
    tap_root = Pathname(__dir__).parent
    patch_dir = tap_root/"packages/kanata-with-cmd/patches"
    patches = (patch_dir/"series").readlines(chomp: true).map { |name| patch_dir/name }
    odie "Kanata patch series is empty: #{patch_dir}" if patches.empty?

    system "git", "apply", *patches

    # Cargo install does not build test targets; only compile the managed
    # executable if upstream adds more binaries to the crate.
    system "cargo", "install", "--bin", "kanata", "--features", "cmd", *std_cargo_args
  end

  test do
    (testpath/"kanata.kbd").write <<~LISP
      (defsrc
        caps
      )

      (deflayer base
        caps
      )
    LISP

    system bin/"kanata", "--check", "--cfg", testpath/"kanata.kbd", "--no-wait"
  end
end
