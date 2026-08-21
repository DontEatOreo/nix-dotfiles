#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "optparse"
require "pathname"

# Installs and inspects the local Shottr activation state.
module ShottrLicense
  class Error < StandardError; end

  DOMAIN = ENV.fetch("SHOTTR_DEFAULTS_DOMAIN", "cc.ffitch.shottr").freeze
  DEFAULTS = ENV.fetch("SHOTTR_DEFAULTS", "/usr/bin/defaults").freeze
  OSASCRIPT = ENV.fetch("SHOTTR_OSASCRIPT", "/usr/bin/osascript").freeze
  SOPS = ENV.fetch("SHOTTR_SOPS", "sops").freeze
  LICENSE_PATTERN = /\A[A-Z0-9]{6}(?:-[A-Z0-9]{6}){4}\z/
  ACTIVATION_SCRIPT = Pathname(
    ENV.fetch(
      "SHOTTR_ACTIVATION_SCRIPT",
      Pathname(__FILE__).realpath.dirname/"activate-shottr-license.applescript",
    ),
  ).freeze

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

  def license_key
    stdout, stderr, status = Open3.capture3(
      SOPS,
      "--decrypt",
      "--extract",
      '["shottr-license-key"]',
      secrets_file.to_s,
    )
    unless status.success?
      details = stderr.strip
      details = stdout.strip if details.empty?
      message = "sops could not decrypt the Shottr license key"
      message = "#{message}\n#{details}" unless details.empty?
      raise Error, message
    end

    key = stdout.strip
    raise Error, "Shottr license key in SOPS has an unexpected format" unless LICENSE_PATTERN.match?(key)

    key
  end

  def activated?
    %w[kc-license kc-vault].all? do |key|
      system(
        DEFAULTS,
        "read",
        DOMAIN,
        key,
        out: File::NULL,
        err: File::NULL,
      )
    end
  end

  def activate(key)
    raise Error, "Shottr activation script not found: #{ACTIVATION_SCRIPT}" unless ACTIVATION_SCRIPT.file?

    stdout, stderr, status = Open3.capture3(
      OSASCRIPT,
      ACTIVATION_SCRIPT.to_s,
      key,
    )
    return if status.success?

    details = stderr.strip
    details = stdout.strip if details.empty?
    message = "Shottr activation UI automation failed"
    if details.include?("not allowed assistive access") || details.include?("-25211")
      message = [
        message,
        "macOS denied Accessibility access to osascript.",
        "Grant Accessibility to the terminal running provisioning in",
        "System Settings > Privacy & Security > Accessibility, then rerun",
        "`shottr-license install --force`.",
      ].join(" ")
    end
    message = "#{message}\n#{details}" unless details.empty?
    raise Error, message
  end

  def install(force: false)
    if activated? && !force
      warn "shottr-license: Shottr already has activation state; leaving it in place"
      return
    end
    activate(license_key)
    warn "shottr-license: submitted license key through Shottr activation UI"
  end

  def status
    state = activated? ? "installed" : "not installed"
    puts "shottr-license: #{state}"
  end

  def usage
    <<~TEXT
      Usage: shottr-license <command> [options]

      Commands:
        install [--force]  Activate Shottr with the SOPS-managed license key
        status             Show the installed Shottr activation state

      Environment:
        SHOTTR_SECRETS_FILE       Override the path to secrets/secrets.yaml
        SHOTTR_ACTIVATION_SCRIPT  Override the activation AppleScript path
    TEXT
  end

  def main(arguments)
    command = arguments.shift
    case command
    when "install"
      force = false
      parser = OptionParser.new do |options|
        options.banner = "Usage: shottr-license install [--force]"
        options.on("--force", "Submit the license even when state exists") do
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
