# frozen_string_literal: true

require "json"

class Equilotl < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  pin = pins.fetch("equilotl")
  archive = pins.fetch("equilotl_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")
  UPSTREAM_REVISION = pin.fetch("revision").freeze
  UPSTREAM_TAG = pin.fetch("version").freeze

  desc "Cross-platform Equicord installer and repair CLI"
  homepage "https://github.com/Equicord/Equilotl"
  url archive.fetch("url")
  version "release-#{UPSTREAM_TAG.delete_prefix("v")}"
  sha256 digest
  license "GPL-3.0-only"

  depends_on "go" => :build

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    depends_on arch: :x86_64
  end

  def install
    executable = OS.mac? ? "EquilotlCli-darwin-arm64" : "EquilotlCli-linux"
    ldflags = [
      "-X equilotl/buildinfo.InstallerGitHash=#{UPSTREAM_REVISION[0, 7]}",
      "-X equilotl/buildinfo.InstallerTag=#{UPSTREAM_TAG}",
    ]
    system "go", "build", *std_go_args(output: bin/executable, ldflags:, tags: "cli")
    bin.install_symlink executable => "equilotl"
  end
end
