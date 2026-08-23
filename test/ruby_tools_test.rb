# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"

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

  def test_raycast_configuration_can_skip_an_absent_profile
    Dir.mktmpdir("raycast-manager-test-") do |directory|
      root = Pathname(directory)
      app = root/"Raycast.app"
      app.mkpath
      data_addon = root/"data.darwin-arm64.node"
      data_addon.write("fixture")
      configuration = Raycast::Configuration.new(
        environment: {
          "RAYCAST_APP"          => app.to_s,
          "RAYCAST_DATA_ADDON"   => data_addon.to_s,
          "RAYCAST_PROFILE_FILE" => (root/"missing-profile.json").to_s,
        },
      )

      refute Raycast::Manager.new(configuration:).configure(if_present: true)
    end
  end
end
