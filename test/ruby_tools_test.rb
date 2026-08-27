# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"

REPOSITORY_ROOT = Pathname(__dir__).parent.freeze

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

  def test_records_workspace_round_trips_and_skips_an_unchanged_pack
    Dir.mktmpdir("records-test-") do |directory|
      root = Pathname(directory)
      repository = root/"repository"
      secrets = repository/"secrets"
      secrets.mkpath
      (repository/".sops.yaml").write("creation_rules: []\n")
      vault = secrets/"records.yaml"
      vault.write("fixture: true\n")
      state_file = root/"state.json"
      log = root/"sops.log"
      state_file.write(
        JSON.generate(
          "items" => {
            "t0" => [
              {
                "body"       => "target body\n",
                "executable" => false,
                "paths"      => [".config/tool/config.txt"],
                "private"    => true,
                "render"     => false,
                "systems"    => [],
              },
            ],
          },
        ),
      )
      sops = write_executable(root/"sops", "#!#{RbConfig.ruby}\n" + <<~RUBY)
        require "json"

        state_file = ENV.fetch("RECORDS_TEST_STATE")
        state = JSON.parse(File.read(state_file))
        filename_override = nil
        if ARGV.first == "--filename-override"
          ARGV.shift
          filename_override = ARGV.shift
        end
        case ARGV.shift
        when "decrypt"
          if ENV["RECORDS_TEST_FAIL_DECRYPT"] == "1"
            warn "injected decrypt failure"
            exit 42
          end

          encoded = state.fetch("items").transform_values { |manifest| JSON.generate(manifest) }
          puts JSON.generate(encoded)
        when "set"
          raise "missing filename override" unless filename_override == ENV.fetch("RECORDS_FILE")

          if ENV["RECORDS_TEST_FAIL_SET"] == "1"
            File.write(ARGV.fetch(-2), "partial replacement\n")
            warn "injected set failure"
            exit 42
          end

          items = JSON.parse($stdin.read)
          state["items"] = items.transform_values { |manifest| JSON.parse(manifest) }
          File.write(state_file, JSON.generate(state))
          File.write(ARGV.fetch(-2), "encrypted fixture\n")
          File.open(ENV.fetch("RECORDS_TEST_LOG"), "a") { |file| file.puts("set") }
        else
          raise "unexpected sops command"
        end
      RUBY
      environment = {
        "RECORDS_FILE"       => vault.to_s,
        "RECORDS_REPOSITORY" => repository.to_s,
        "RECORDS_SOPS"       => sops.to_s,
        "RECORDS_TEST_LOG"   => log.to_s,
        "RECORDS_TEST_STATE" => state_file.to_s,
      }
      workspace = root/"workspace"

      existing_workspace = root/"existing-workspace"
      existing_workspace.mkdir(0o700)
      _, stderr, status = run_tool(
        "records.rb",
        "unpack",
        existing_workspace.to_s,
        environment: environment.merge("RECORDS_TEST_FAIL_DECRYPT" => "1"),
      )
      refute status.success?
      assert_includes stderr, "injected decrypt failure"
      assert existing_workspace.directory?
      assert_empty existing_workspace.children

      failed_workspace = root/"failed-workspace"
      _, stderr, status = run_tool(
        "records.rb",
        "unpack",
        failed_workspace.to_s,
        environment: environment.merge("RECORDS_TEST_FAIL_DECRYPT" => "1"),
      )
      refute status.success?
      assert_includes stderr, "injected decrypt failure"
      refute failed_workspace.exist?

      _, stderr, status = run_tool("records.rb", "unpack", workspace.to_s, environment:)
      assert status.success?, stderr
      assert_equal "target body\n", (workspace/"t0/000/body").read
      assert_equal 0, workspace.stat.mode & 0o077
      assert_equal ["t0"], JSON.load_file(workspace/"format.json").fetch("collections")

      (workspace/"t0/000/body").write("changed target body\n")
      _, stderr, status = run_tool("records.rb", "pack", workspace.to_s, environment:)
      assert status.success?, stderr
      state = JSON.parse(state_file.read)
      assert_equal "changed target body\n", state.dig("items", "t0", 0, "body")

      vault_before_failure = vault.binread
      mode_before_failure = vault.stat.mode
      (workspace/"t0/000/body").write("failed update\n")
      _, stderr, status = run_tool(
        "records.rb",
        "pack",
        workspace.to_s,
        environment: environment.merge("RECORDS_TEST_FAIL_SET" => "1"),
      )
      refute status.success?
      assert_includes stderr, "injected set failure"
      assert_equal vault_before_failure, vault.binread
      assert_equal mode_before_failure, vault.stat.mode

      (workspace/"t0/000/body").write("changed target body\n")
      stdout, stderr, status = run_tool("records.rb", "pack", workspace.to_s, environment:)
      assert status.success?, stderr
      assert_includes stdout, "records unchanged"
      assert_equal 1, log.readlines.length
    end
  end
end
