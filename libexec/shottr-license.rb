#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "pathname"

# Installs and inspects the local Shottr activation state without UI automation.
module ShottrLicense
  class Error < StandardError; end

  PLUTIL = ENV.fetch("SHOTTR_PLUTIL", "/usr/bin/plutil").freeze
  PKILL = ENV.fetch("SHOTTR_PKILL", "/usr/bin/pkill").freeze
  OPEN = ENV.fetch("SHOTTR_OPEN", "/usr/bin/open").freeze
  SOPS = ENV.fetch("SHOTTR_SOPS", "sops").freeze
  PREFERENCES_FILE = Pathname(
    ENV.fetch("SHOTTR_PREFERENCES_FILE") do
      Pathname(Dir.home)/"Library/Preferences/cc.ffitch.shottr.plist"
    end,
  ).expand_path.freeze
  STATE_KEYS = {
    "license" => ["kc-license", 34],
    "vault"   => ["kc-vault", 64],
  }.freeze

  module_function

  def secrets_file
    configured = ENV.fetch("SHOTTR_SECRETS_FILE", nil)
    return Pathname(configured).expand_path unless configured.to_s.empty?

    bundled = Pathname(__FILE__).realpath.dirname/"secrets.yaml"
    return bundled if bundled.file?

    Pathname.pwd.ascend do |directory|
      candidate = directory/"secrets/secrets.yaml"
      return candidate if candidate.file?
    end
    raise Error, "could not find secrets/secrets.yaml from #{Pathname.pwd}"
  end

  def managed_state
    stdout, stderr, status = Open3.capture3(
      SOPS,
      "--decrypt",
      "--extract",
      '["shottr-license-state"]',
      "--output-type",
      "json",
      secrets_file.to_s,
    )
    unless status.success?
      details = stderr.strip
      details = stdout.strip if details.empty?
      message = "sops could not decrypt the Shottr license state"
      message = "#{message}\n#{details}" unless details.empty?
      raise Error, message
    end

    state = JSON.parse(stdout)
    raise Error, "Shottr license state is not a JSON object" unless state.is_a?(Hash)

    state = state.slice(*STATE_KEYS.keys)
    STATE_KEYS.each_key do |name|
      next if valid_value?(name, state[name])

      raise Error, "Shottr #{name} state has an unexpected format"
    end
    state
  rescue JSON::ParserError => e
    raise Error, "Shottr license state is not valid JSON (#{e.message})"
  end

  def read_preference(key)
    return nil unless PREFERENCES_FILE.file?

    stdout, _, status = Open3.capture3(
      PLUTIL,
      "-extract",
      key,
      "raw",
      "-expect",
      "string",
      PREFERENCES_FILE.to_s,
    )
    status.success? ? stdout.strip : nil
  end

  def installed_state
    STATE_KEYS.to_h do |name, (preference, _)|
      [name, read_preference(preference)]
    end
  end

  def activated?
    installed_state.all? { |name, value| valid_value?(name, value) }
  end

  def valid_value?(name, value)
    value.is_a?(String) &&
      value.unpack1("m0").bytesize == STATE_KEYS.fetch(name).last
  rescue ArgumentError
    false
  end

  def run!(*arguments)
    stdout, stderr, status = Open3.capture3(*arguments)
    return stdout if status.success?

    details = stderr.strip
    details = stdout.strip if details.empty?
    message = "command failed (#{status.exitstatus}): #{arguments.first}"
    message = "#{message}\n#{details}" unless details.empty?
    raise Error, message
  end

  def stop_shottr
    system(PKILL, "-x", "Shottr", out: File::NULL, err: File::NULL)
  end

  def write_state(state, current_state)
    run!(PLUTIL, "-create", "xml1", PREFERENCES_FILE.to_s) unless PREFERENCES_FILE.file?
    STATE_KEYS.each do |name, (preference, _)|
      operation = current_state[name] ? "-replace" : "-insert"
      run!(
        PLUTIL,
        operation,
        preference,
        "-string",
        state.fetch(name),
        PREFERENCES_FILE.to_s,
      )
    end
  end

  def install(force: false)
    state = managed_state
    current_state = installed_state
    if current_state == state && !force
      warn "shottr-license: Shottr already has the managed license state; leaving it in place"
      return
    end

    stop_shottr
    write_state(state, current_state)
    system(OPEN, "-a", "Shottr", out: File::NULL, err: File::NULL)
    warn "shottr-license: license state installed"
  end

  def status
    state = activated? ? "installed" : "not installed"
    puts "shottr-license: #{state}"
  end

  def usage
    <<~TEXT
      Usage: shottr-license <command> [options]

      Commands:
        install [--force]  Restore the SOPS-managed Shottr license state
        status             Show the installed Shottr activation state

      Environment:
        SHOTTR_SECRETS_FILE      Override the path to secrets/secrets.yaml
        SHOTTR_PREFERENCES_FILE  Override Shottr's preferences plist path
    TEXT
  end

  def main(arguments)
    command = arguments.shift
    case command
    when "install"
      force = false
      parser = OptionParser.new do |options|
        options.banner = "Usage: shottr-license install [--force]"
        options.on("--force", "Restore the license state even when it matches") do
          force = true
        end
        options.on("-h", "--help", "Show this help") do
          puts options
          return 0
        end
      end
      parser.parse!(arguments)
      reject_arguments(arguments)
      install(force:)
    when "status"
      reject_arguments(arguments)
      status
    when "--help", "-h", "help", nil
      reject_arguments(arguments)
      puts usage
    else
      raise Error, "unknown command: #{command}"
    end
    0
  end

  def reject_arguments(arguments)
    return if arguments.empty?

    raise OptionParser::InvalidArgument, arguments.join(" ")
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    exit ShottrLicense.main(ARGV)
  rescue ShottrLicense::Error,
         Errno::ENOENT,
         RuntimeError => e
    warn "shottr-license: error: #{e.message}"
    exit 1
  end
end
