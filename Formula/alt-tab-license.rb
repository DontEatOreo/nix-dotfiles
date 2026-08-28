# frozen_string_literal: true

class AltTabLicense < Formula
  MANAGER_SOURCE = (Pathname(__dir__).parent/"libexec/alt-tab-license.rb").freeze

  desc "Dotfiles-managed AltTab license activation"
  homepage "https://github.com/lwouis/alt-tab-macos"
  url "file://#{MANAGER_SOURCE}"
  version "1"
  sha256 MANAGER_SOURCE.sha256
  license "MIT"

  depends_on macos: :tahoe
  depends_on "ruby"

  def install
    libexec.install "alt-tab-license.rb"
    chmod 0755, libexec/"alt-tab-license.rb"
    bin.install_symlink (libexec/"alt-tab-license.rb") => "alt-tab-license"
  end
end
