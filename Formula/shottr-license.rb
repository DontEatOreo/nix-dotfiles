# frozen_string_literal: true

class ShottrLicense < Formula
  REPOSITORY_ROOT = Pathname(__dir__).parent.freeze
  MANAGER_SOURCE = (REPOSITORY_ROOT/"libexec/shottr-license.rb").freeze
  SECRETS_SOURCE = begin
    tap_source = REPOSITORY_ROOT/"secrets/secrets.yaml"
    tap_source.file? ? tap_source : REPOSITORY_ROOT/"libexec/secrets.yaml"
  end.freeze

  desc "Dotfiles-managed Shottr license activation"
  homepage "https://shottr.cc/"
  url "file://#{MANAGER_SOURCE}"
  version "1"
  sha256 MANAGER_SOURCE.sha256
  license "MIT"

  depends_on macos: :tahoe
  depends_on "ruby"
  depends_on "sops"

  resource "secrets" do
    url "file://#{SECRETS_SOURCE}"
    sha256 SECRETS_SOURCE.sha256
  end

  def install
    libexec.install "shottr-license.rb"
    resource("secrets").stage do
      libexec.install "secrets.yaml"
    end
    chmod "+x", libexec/"shottr-license.rb"
    chmod "go-rwx", libexec/"secrets.yaml"
    bin.install_symlink (libexec/"shottr-license.rb") => "shottr-license"
  end
end
