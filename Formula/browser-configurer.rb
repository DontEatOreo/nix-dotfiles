# frozen_string_literal: true

require "json"

class BrowserConfigurer < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  pin = pins.fetch("browser")
  archive = pins.fetch("browser_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Configure Chromium-family browsers and extension profiles"
  homepage "https://github.com/4evy/browser"
  url archive.fetch("url")
  version "git-#{pin.fetch("revision")[0, 8]}"
  sha256 digest
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: bin/"browser-configurer"), "./cmd/browser"
  end

  test do
    assert_match "Configure a Chromium-family browser", shell_output("#{bin}/browser-configurer --help")
  end
end
