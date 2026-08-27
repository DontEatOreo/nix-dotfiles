#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "optparse"

# Installs and inspects the local AltTab license state.
module AltTabLicense
  class Error < StandardError; end

  SECURITY = ENV.fetch("ALT_TAB_SECURITY", "/usr/bin/security").freeze
  DEFAULTS = ENV.fetch("ALT_TAB_DEFAULTS", "/usr/bin/defaults").freeze
  SERVICE = ENV.fetch(
    "ALT_TAB_LICENSE_SERVICE",
    "com.lwouis.alt-tab-macos.license",
  ).freeze
  KEYCHAIN_VALUES = {
    "licenseKey" => "0000-0000-0000-0000-0000-0000",
    "instanceId" => "evy-instance-0",
    "variantId"  => "pro_lifetime",
  }.freeze
  DEFAULT_VALUES = {
    "lastValidation"       => ["float", -> { Time.now.to_i.to_s }],
    "lastValidationResult" => ["bool", -> { "true" }],
    "customerEmail"        => ["string", -> { "alt@evy.pink" }],
  }.freeze

  module_function

  def remove_keychain_items
    KEYCHAIN_VALUES.each_key do |account|
      system(
        SECURITY,
        "delete-generic-password",
        "-s",
        SERVICE,
        "-a",
        account,
        out: File::NULL,
        err: File::NULL,
      )
    end
  end

  def installed?
    keychain_items_present = KEYCHAIN_VALUES.each_key.all? do |account|
      system(
        SECURITY,
        "find-generic-password",
        "-s",
        SERVICE,
        "-a",
        account,
        out: File::NULL,
        err: File::NULL,
      )
    end
    defaults_present = DEFAULT_VALUES.each_key.all? do |key|
      system(
        DEFAULTS,
        "read",
        SERVICE,
        key,
        out: File::NULL,
        err: File::NULL,
      )
    end
    keychain_items_present && defaults_present
  end

  def install(force: false)
    if installed? && !force
      warn "alt-tab-license: AltTab already has license state; leaving it in place"
      return
    end
    remove_keychain_items
    KEYCHAIN_VALUES.each do |account, value|
      system(
        SECURITY,
        "add-generic-password",
        "-A",
        "-U",
        "-s",
        SERVICE,
        "-a",
        account,
        "-w",
        value,
        exception: true,
      )
    end
    DEFAULT_VALUES.each do |key, (kind, value)|
      system(
        DEFAULTS,
        "write",
        SERVICE,
        key,
        "-#{kind}",
        value.call,
        exception: true,
      )
    end
    warn "alt-tab-license: license installed; restart AltTab to apply"
  end

  def remove
    remove_keychain_items
    DEFAULT_VALUES.each_key do |key|
      system(
        DEFAULTS,
        "delete",
        SERVICE,
        key,
        out: File::NULL,
        err: File::NULL,
      )
    end
    warn "alt-tab-license: license removed; restart AltTab to revert to trial"
  end

  def read(*command)
    stdout, status = Open3.capture2(*command, err: File::NULL)
    value = stdout.strip
    status.success? && !value.empty? ? value : "none"
  end

  def status
    puts "keychain items:"
    KEYCHAIN_VALUES.each_key do |account|
      value = read(
        SECURITY,
        "find-generic-password",
        "-s",
        SERVICE,
        "-a",
        account,
        "-w",
      )
      puts format(
        "  %<label>-12s %<value>s",
        label: "#{account}:",
        value:,
      )
    end
    puts "\ndefaults (#{SERVICE}):"
    DEFAULT_VALUES.each_key do |key|
      value = read(DEFAULTS, "read", SERVICE, key)
      puts format(
        "  %<label>-22s %<value>s",
        label: "#{key}:",
        value:,
      )
    end
  end

  def usage
    <<~TEXT
      Usage: alt-tab-license <command>

      Commands:
        install [--force]  Install or refresh the local AltTab license state
        remove   Remove the local AltTab license state
        status   Show the installed AltTab license state
    TEXT
  end

  def main(arguments)
    command = arguments.shift

    case command
    when "install"
      force = false
      parser = OptionParser.new do |options|
        options.banner = "Usage: alt-tab-license install [--force]"
        options.on("--force", "Replace existing license state") { force = true }
        options.on("-h", "--help", "Show this help") do
          puts options
          return 0
        end
      end
      parser.parse!(arguments)
      reject_arguments(arguments)

      install(force:)
    when "remove"
      reject_arguments(arguments)
      remove
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
    exit AltTabLicense.main(ARGV)
  rescue AltTabLicense::Error,
         Errno::ENOENT,
         RuntimeError => e
    warn "alt-tab-license: error: #{e.message}"
    exit 1
  end
end
