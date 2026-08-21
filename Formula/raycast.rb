# frozen_string_literal: true

require "digest"

class Raycast < Formula
  MANAGER_SOURCE = (Pathname(__dir__).parent/"libexec/raycast-manager.rb").freeze

  desc "Stable Raycast release with dotfiles integration"
  homepage "https://www.raycast.com/"
  url "file://#{MANAGER_SOURCE}"
  version "1"
  sha256 Digest::SHA256.file(MANAGER_SOURCE).hexdigest
  license :cannot_represent

  depends_on arch: :arm64
  depends_on macos: :tahoe
  depends_on "ruby"

  deny_network_access! [:build, :test]

  def install
    libexec.install "raycast-manager.rb"
    inreplace libexec/"raycast-manager.rb",
              "#!/usr/bin/env ruby",
              "#!#{formula_opt_bin("ruby")}/ruby"
    chmod 0755, libexec/"raycast-manager.rb"
    bin.install_symlink (libexec/"raycast-manager.rb") => "raycast-manager"
  end

  def caveats
    <<~CAVEATS
      Raycast is copied to:
        /Applications/Raycast.app

      Refresh the app and apply the chezmoi-managed profile, aliases, and AI-disable policy with:
        raycast-manager refresh
    CAVEATS
  end

  test do
    output = shell_output(
      "RAYCAST_APP=#{testpath}/missing.app #{bin}/raycast-manager version",
    )
    assert_equal "not installed", output.strip
  end
end
