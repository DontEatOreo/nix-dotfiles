# frozen_string_literal: true

require "digest"
require "json"

class TerminalThemeTools < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  ghostty = pins.fetch("terminal_theme_tools_ghostty_archive")
  uucode = pins.fetch("terminal_theme_tools_uucode")
  pin_digest = lambda do |pin|
    pin.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")
  end

  SOURCE_ARCHIVE = (Pathname(__dir__).parent/"Sources/terminal-theme-tools-0.3.0.tar").freeze
  SOURCE_SHA256 = Digest::SHA256.file(SOURCE_ARCHIVE).hexdigest.freeze

  desc "Theme-aware launcher for terminal applications"
  homepage "https://github.com/4evy/dotfiles"
  url "file://#{SOURCE_ARCHIVE}"
  sha256 SOURCE_SHA256
  license "MIT"

  depends_on "zig" => :build
  depends_on :macos

  resource "ghostty" do
    url ghostty.fetch("url")
    sha256 pin_digest.call(ghostty)
  end

  resource "uucode" do
    url uucode.fetch("url")
    sha256 pin_digest.call(uucode)
  end

  def install
    resources.each do |resource|
      resource.stage buildpath/".deps"/resource.name
    end

    inreplace "build.zig.zon" do |s|
      s.gsub!(/\.ghostty = \.\{.*?^\s*\},/m, '.ghostty = .{ .path = ".deps/ghostty" },')
    end
    inreplace ".deps/ghostty/build.zig.zon" do |s|
      s.gsub!(/\.uucode = \.\{.*?^\s*\},/m, '.uucode = .{ .path = "../uucode" },')
    end
    inreplace ".deps/ghostty/src/build/Config.zig" do |s|
      old_default = <<~ZIG.chomp
        ) orelse emit_xcfw: {
                if (!builtin.target.os.tag.isDarwin()
      ZIG
      dependency_default = <<~ZIG.chomp
        ) orelse emit_xcfw: {
                if (is_dep) break :emit_xcfw false;
                if (!builtin.target.os.tag.isDarwin()
      ZIG
      replaced = s.sub!(
        old_default,
        dependency_default,
      )
      odie "Ghostty dependency-mode default changed upstream" unless replaced
    end

    system "zig", "build", "--release=small", "--prefix", prefix
    (pkgshare/"source.sha256").write("#{SOURCE_SHA256}\n")
  end

  test do
    assert_path_exists include/"terminal_theme_tools.h"
    assert_path_exists lib/"libterminal_theme_tools.a"
    assert_match version.to_s, shell_output("#{bin}/terminal-theme-run --version")
    assert_match "Usage: terminal-theme-run", shell_output("#{bin}/terminal-theme-run --help")
    system bin/"terminal-theme-run", "true"
  end
end
