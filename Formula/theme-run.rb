# frozen_string_literal: true

class ThemeRun < Formula
  SOURCE_ARCHIVE = (Pathname(__dir__).parent/"Sources/theme-run-0.1.0.tar").freeze
  SOURCE_SHA256 = SOURCE_ARCHIVE.sha256.freeze

  desc "Theme-aware launcher for terminal applications"
  homepage "https://github.com/4evy/dotfiles"
  url "file://#{SOURCE_ARCHIVE}"
  sha256 SOURCE_SHA256
  license "MIT"

  depends_on "go" => :build

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["CGO_ENABLED"] = "0"
    ENV["GOPROXY"] = "off"
    system "go", "build", *std_go_args(output: bin/"theme-run"), "./cmd/theme-run"
    (pkgshare/"source.sha256").write("#{SOURCE_SHA256}\n")
  end
end
