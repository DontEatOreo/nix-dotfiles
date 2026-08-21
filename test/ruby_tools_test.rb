# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"
require "webmock/minitest"

REPOSITORY_ROOT = Pathname(__dir__).parent.freeze

require REPOSITORY_ROOT/"libexec/raycast-manager"

class RubyToolsTest < Minitest::Test
  def run_tool(name, *arguments, environment: {})
    Open3.capture3(
      environment,
      RbConfig.ruby,
      (REPOSITORY_ROOT/"libexec"/name).to_s,
      *arguments,
    )
  end

  def write_executable(path, source)
    path.write(source)
    path.chmod(0o755)
    path
  end

  def test_alt_tab_install_uses_argument_arrays_for_native_tools
    Dir.mktmpdir("alt-tab-license-test-") do |directory|
      root = Pathname(directory)
      log = root/"commands.log"
      command = write_executable(root/"native-command", <<~RUBY)
        #!#{RbConfig.ruby}
        File.open(ENV.fetch("COMMAND_LOG"), "a") { |file| file.puts(ARGV.join("\t")) }
        exit(%w[find-generic-password read delete-generic-password].include?(ARGV.first) ? 1 : 0)
      RUBY

      _, stderr, status = run_tool(
        "alt-tab-license.rb",
        "install",
        environment: {
          "ALT_TAB_SECURITY" => command.to_s,
          "ALT_TAB_DEFAULTS" => command.to_s,
          "COMMAND_LOG"      => log.to_s,
        },
      )

      assert status.success?, stderr
      commands = log.readlines(chomp: true)
      assert_equal(3, commands.count { |line| line.start_with?("add-generic-password\t") })
      assert_equal(3, commands.count { |line| line.start_with?("write\t") })
    end
  end

  def test_shottr_install_restores_sops_state_without_ui_automation
    Dir.mktmpdir("shottr-license-test-") do |directory|
      root = Pathname(directory)
      secrets = root/"secrets.yaml"
      secrets.write("fixture: true\n")
      preferences = root/"cc.ffitch.shottr.plist"
      preferences.write("fixture\n")
      log = root/"plutil.log"
      plutil = write_executable(root/"plutil", <<~RUBY)
        #!#{RbConfig.ruby}
        File.open(ENV.fetch("PLUTIL_LOG"), "a") { |file| file.puts(ARGV.join("\t")) }
        if ARGV.first == "-extract"
          exit 1
        end
      RUBY
      sops = write_executable(root/"sops", <<~RUBY)
        #!#{RbConfig.ruby}
        puts ENV.fetch("SHOTTR_STATE")
      RUBY
      license = ["L" * 34].pack("m0")
      vault = ["V" * 64].pack("m0")

      _, stderr, status = run_tool(
        "shottr-license.rb",
        "install",
        environment: {
          "SHOTTR_OPEN"             => "/usr/bin/true",
          "SHOTTR_PKILL"            => "/usr/bin/false",
          "SHOTTR_PLUTIL"           => plutil.to_s,
          "SHOTTR_PREFERENCES_FILE" => preferences.to_s,
          "SHOTTR_SECRETS_FILE"     => secrets.to_s,
          "SHOTTR_SOPS"             => sops.to_s,
          "SHOTTR_STATE"            => JSON.generate("license" => license, "vault" => vault),
          "PLUTIL_LOG"              => log.to_s,
        },
      )

      assert status.success?, stderr
      assert_includes stderr, "license state installed"
      commands = log.readlines(chomp: true)
      extract_count = commands.count { |command| command.start_with?("-extract\t") }
      assert_equal 2, extract_count
      assert_includes commands, ["-insert", "kc-license", "-string", license, preferences].join("\t")
      assert_includes commands, ["-insert", "kc-vault", "-string", vault, preferences].join("\t")
    end
  end

  def test_raycast_latest_release_uses_release_api
    request = stub_request(:get, "https://example.com/releases/latest").with(
      query:   {
        "architecture" => "arm64",
        "platform"     => "macos",
        "version"      => "0.0.0.0",
      },
      headers: {
        "Accept"     => "application/json",
        "User-Agent" => Raycast::USER_AGENT,
      },
    ).to_return(
      status:  200,
      headers: { "Content-Type" => "application/json" },
      body:    JSON.generate(
        "version"      => "2.0.3.0",
        "download_url" =>
                          "https://x-r2.raycast-releases.com/" \
                          "Raycast_2.0.3.0_bbbb_arm64.dmg",
      ),
    )
    configuration = Raycast::Configuration.new(
      environment: { "RAYCAST_RELEASE_API" => "https://example.com/releases/latest" },
    )

    release = Raycast::Manager.new(configuration:).latest_release

    assert_equal Gem::Version.new("2.0.3.0"), release.version
    assert_equal "/Raycast_2.0.3.0_bbbb_arm64.dmg", release.uri.path
    assert_nil release.checksum
    assert_requested request
  end

  def test_raycast_latest_release_reads_optional_dmg_checksum
    stub_request(:get, "https://example.com/releases/latest").with(
      query: {
        "architecture" => "arm64",
        "platform"     => "macos",
        "version"      => "0.0.0.0",
      },
    ).to_return(
      status:  200,
      headers: { "Content-Type" => "application/json" },
      body:    JSON.generate(
        "version"      => "2.0.3.0",
        "download_url" =>
                          "https://x-r2.raycast-releases.com/" \
                          "Raycast_2.0.3.0_bbbb_arm64.dmg",
        "checksum"     => "DE2E95CB97F221D894ED8810A69102CD",
      ),
    )
    configuration = Raycast::Configuration.new(
      environment: { "RAYCAST_RELEASE_API" => "https://example.com/releases/latest" },
    )

    release = Raycast::Manager.new(configuration:).latest_release

    assert_equal "de2e95cb97f221d894ed8810a69102cd", release.checksum
  end

  def test_raycast_latest_release_rejects_unexpected_checksum
    stub_request(:get, "https://example.com/releases/latest").with(
      query: {
        "architecture" => "arm64",
        "platform"     => "macos",
        "version"      => "0.0.0.0",
      },
    ).to_return(
      status:  200,
      headers: { "Content-Type" => "application/json" },
      body:    JSON.generate(
        "version"      => "2.0.3.0",
        "download_url" =>
                          "https://x-r2.raycast-releases.com/" \
                          "Raycast_2.0.3.0_bbbb_arm64.dmg",
        "checksum"     => "not-an-md5",
      ),
    )
    configuration = Raycast::Configuration.new(
      environment: { "RAYCAST_RELEASE_API" => "https://example.com/releases/latest" },
    )

    error = assert_raises(Raycast::Error) do
      Raycast::Manager.new(configuration:).latest_release
    end
    assert_match(/unexpected checksum/, error.message)
  end
end
