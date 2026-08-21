# frozen_string_literal: true

require "json"

class HelixTip < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  pin = pins.fetch("helix")
  archive = pins.fetch("helix_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Post-release Helix editor build pinned by the dotfiles lock"
  homepage "https://helix-editor.com"
  url archive.fetch("url")
  version "git-#{pin.fetch("revision")[0, 8]}"
  sha256 digest
  license "MPL-2.0"
  head "https://github.com/#{pin.dig("repository", "owner")}/#{pin.dig("repository", "repo")}.git",
       branch: pin.fetch("branch")

  depends_on "rust" => :build

  conflicts_with "helix", because: "both install an hx binary"

  def install
    runtime = libexec/"runtime"
    ENV["HELIX_DEFAULT_RUNTIME"] = runtime

    # GitLab rejects anonymous Git fetches for these grammar repositories.
    # Keep the rest of Helix's pinned grammar set available instead of making
    # the entire editor build depend on the unavailable remotes.
    inreplace "languages.toml",
              'use-grammars = { except = [ "wren", "gemini" ] }',
              'use-grammars = { except = [ "wren", "gemini", "lpf", "blueprint", "t32", ' \
              '"rpmspec", "nginx", "debian" ] }'

    system "cargo", "install", *std_cargo_args(path: "helix-term")
    runtime.install Dir["runtime/*"]
    rm_r runtime/"grammars/sources"
  end
end
