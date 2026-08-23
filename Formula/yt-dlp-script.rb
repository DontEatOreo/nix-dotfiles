# frozen_string_literal: true

require "json"

class YtDlpScript < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  pin = pins.fetch("yt_dlp_script")
  archive = pins.fetch("yt_dlp_script_archive")
  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Opinionated yt-dlp download and media conversion workflow"
  homepage "https://github.com/euvlok/pkgs"
  url archive.fetch("url")
  version "git-#{pin.fetch("revision")[0, 8]}"
  sha256 digest
  license "MIT"

  depends_on "bash"
  depends_on "ffmpeg"
  depends_on "jq"
  depends_on "yt-dlp"

  def install
    bin.install "pkgs/by-name/yt/yt-dlp-script/yt-dlp-script.sh" => "yt-dlp-script"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/yt-dlp-script --help")
  end
end
