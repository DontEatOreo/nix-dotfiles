# frozen_string_literal: true

require "json"

class HeliumLinux < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  binary = pins.fetch("helium_linux_binary")
  digest = binary.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Chromium-based Helium browser for Linux"
  homepage "https://helium.computer/"
  url binary.fetch("url")
  sha256 digest
  license "GPL-3.0-only"

  depends_on arch: :x86_64
  depends_on :linux

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"helium" => "helium"
  end
end
