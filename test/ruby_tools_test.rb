# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "pathname"
require "rbconfig"
require "socket"
require "stringio"
require "tmpdir"

REPOSITORY_ROOT = Pathname(__dir__).parent.freeze

require REPOSITORY_ROOT/"libexec/raycast-beta-manager"

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

  def test_alt_tab_status_handles_absent_state
    stdout, stderr, status = run_tool(
      "alt-tab-license.rb",
      "status",
      environment: {
        "ALT_TAB_SECURITY" => "/usr/bin/false",
        "ALT_TAB_DEFAULTS" => "/usr/bin/false",
      },
    )

    assert status.success?, stderr
    assert_includes stdout, "licenseKey:  none"
    assert_includes stdout, "lastValidation:        none"
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

  def test_shottr_install_uses_sops_output_and_osascript
    Dir.mktmpdir("shottr-license-test-") do |directory|
      root = Pathname(directory)
      secrets = root/"secrets.yaml"
      activation = root/"activate.applescript"
      activation.write("-- fixture\n")
      secrets.write("fixture: true\n")
      defaults = write_executable(root/"defaults", <<~RUBY)
        #!#{RbConfig.ruby}
        exit 1
      RUBY
      sops = write_executable(root/"sops", <<~RUBY)
        #!#{RbConfig.ruby}
        puts "ABCDEF-ABCDEF-ABCDEF-ABCDEF-ABCDEF"
      RUBY
      osascript = write_executable(root/"osascript", <<~RUBY)
        #!#{RbConfig.ruby}
        File.write(ENV.fetch("OSASCRIPT_LOG"), ARGV.join("\n"))
      RUBY
      log = root/"osascript.log"

      _, stderr, status = run_tool(
        "shottr-license.rb",
        "install",
        environment: {
          "SHOTTR_DEFAULTS"          => defaults.to_s,
          "SHOTTR_SOPS"              => sops.to_s,
          "SHOTTR_OSASCRIPT"         => osascript.to_s,
          "SHOTTR_SECRETS_FILE"      => secrets.to_s,
          "SHOTTR_ACTIVATION_SCRIPT" => activation.to_s,
          "OSASCRIPT_LOG"            => log.to_s,
        },
      )

      assert status.success?, stderr
      assert_equal [
        activation.to_s,
        "ABCDEF-ABCDEF-ABCDEF-ABCDEF-ABCDEF",
      ], log.readlines(chomp: true)
    end
  end

  def test_standard_option_parser_rejects_unknown_options
    %w[alt-tab-license.rb shottr-license.rb raycast-beta-manager.rb].each do |tool|
      _, stderr, status = run_tool(tool, "install", "--unknown")

      refute status.success?, tool
      assert_includes stderr, "invalid option: --unknown"
    end
  end

  def test_raycast_configuration_uses_pathname_and_uri
    configuration = RaycastBeta::Configuration.new(
      environment: {
        "RAYCAST_APP"         => "Applications/Raycast Beta.app",
        "RAYCAST_RELEASE_API" => "https://example.com/releases/latest",
      },
      home:        Pathname("/tmp/home"),
    )

    assert_equal Pathname("Applications/Raycast Beta.app").expand_path,
                 configuration.app
    assert_equal URI("https://example.com/releases/latest"), configuration.release_api
  end

  def test_raycast_latest_release_uses_release_api
    responses = {
      "/releases/latest?platform=macos&architecture=arm64&version=0.0.0.0" => [
        200,
        { "Content-Type" => "application/json" },
        JSON.generate(
          "version"      => "1.10.0.0",
          "download_url" =>
                            "https://x-r2.raycast-releases.com/" \
                            "Raycast_Beta_1.10.0.0_bbbb_arm64.dmg",
        ),
      ],
    }

    with_http_server(responses) do |base_url|
      configuration = RaycastBeta::Configuration.new(
        environment: { "RAYCAST_RELEASE_API" => "#{base_url}/releases/latest" },
      )
      release = RaycastBeta::Manager.new(configuration:).latest_release

      assert_equal Gem::Version.new("1.10.0.0"), release.version
      assert_equal "/Raycast_Beta_1.10.0.0_bbbb_arm64.dmg", release.uri.path
    end
  end

  def test_raycast_latest_release_returns_nil_when_current
    responses = {
      "/releases/latest?platform=macos&architecture=arm64&version=1.10.0.0" => [
        204,
        {},
        "",
      ],
    }

    with_http_server(responses) do |base_url|
      configuration = RaycastBeta::Configuration.new(
        environment: { "RAYCAST_RELEASE_API" => "#{base_url}/releases/latest" },
      )
      release = RaycastBeta::Manager.new(configuration:).latest_release(
        current_version: Gem::Version.new("1.10.0.0"),
      )

      assert_nil release
    end
  end

  def test_raycast_file_url_escapes_filesystem_characters
    url = RaycastBeta::Manager.new.file_url("/tmp/avatar #1.png")

    assert_equal "file:///tmp/avatar%20%231.png", url
  end

  private

  def with_http_server(responses)
    server = TCPServer.new("127.0.0.1", 0)
    thread = Thread.new do
      responses.length.times do
        client = server.accept
        request = +""
        request << client.readpartial(1024) until request.include?("\r\n\r\n")
        path = request.lines.first.split.fetch(1)
        status, headers, body = responses.fetch(path)
        reason = { 200 => "OK", 204 => "No Content", 302 => "Found" }.fetch(status)
        response_headers = {
          "Content-Length" => body.bytesize,
          "Connection"     => "close",
        }.merge(headers)
        client.write "HTTP/1.1 #{status} #{reason}\r\n"
        response_headers.each { |name, value| client.write "#{name}: #{value}\r\n" }
        client.write "\r\n#{body}"
        client.close
      end
    end

    yield "http://127.0.0.1:#{server.local_address.ip_port}"
    thread.value
  ensure
    server&.close
    thread&.kill
    thread&.join
  end
end
