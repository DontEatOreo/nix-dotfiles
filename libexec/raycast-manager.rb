#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "open-uri"
require "openssl"
require "optparse"
require "pathname"
require "rubygems/version"
require "shellwords"
require "socket"
require "tempfile"
require "timeout"
require "tmpdir"
require "uri"

# Installs and configures Raycast using dotfiles-managed data.
module Raycast
  PROGRAM_NAME = "raycast-manager"
  APP_NAME = "Raycast"
  EXPECTED_BUNDLE_ID = "com.raycast.macos"
  HTTP_OPEN_TIMEOUT = 30
  HTTP_READ_TIMEOUT = 300
  USER_AGENT = "#{PROGRAM_NAME}/6".freeze
  DMG_CHECKSUM_PATTERN = /\A[a-f0-9]{32}\z/i
  RELEASE_URL_PATTERN = %r{
    \Ahttps://x-r2\.raycast-releases\.com/
    Raycast_(\d+(?:\.\d+)+)_[a-f0-9]+_arm64\.dmg
    \z
  }ix

  Release = Data.define(:uri, :version, :checksum).freeze
  Profile = Data.define(
    :current_user,
    :oauth_token,
    :avatar_url,
    :command_aliases,
  ).freeze

  class Error < StandardError; end

  # Resolves runtime paths once and supports explicit environment overrides.
  class Configuration
    attr_reader :app,
                :app_support,
                :avatar_source,
                :data_addon,
                :database_cli,
                :disable_ai_cli,
                :keydump_hook,
                :lock_file,
                :profile_file,
                :release_api

    def initialize(environment: ENV, home: Pathname(Dir.home))
      @app = path(environment.fetch("RAYCAST_APP", "/Applications/Raycast.app"))
      @app_support = path(
        environment.fetch(
          "RAYCAST_APP_SUPPORT",
          home/"Library/Application Support/com.raycast.macos",
        ),
      )
      profile_directory = path(
        environment.fetch("RAYCAST_PROFILE_DIR", home/".config/raycast"),
      )
      @profile_file = path(
        environment.fetch(
          "RAYCAST_PROFILE_FILE",
          profile_directory/"profile.json",
        ),
      )
      @keydump_hook = path(
        environment.fetch(
          "RAYCAST_KEYDUMP_HOOK",
          profile_directory/"keydump.cts",
        ),
      )
      @database_cli = path(
        environment.fetch(
          "RAYCAST_DB_CLI",
          profile_directory/"raycast-db.mts",
        ),
      )
      @disable_ai_cli = path(
        environment.fetch(
          "RAYCAST_DISABLE_AI_CLI",
          profile_directory/"disable-ai.mts",
        ),
      )
      backend_resources = @app/
                          "Contents/Resources/macos-app_RaycastDesktopApp.bundle/" \
                          "Contents/Resources/backend"
      @data_addon = path(
        environment.fetch(
          "RAYCAST_DATA_ADDON",
          backend_resources/"data.darwin-arm64.node",
        ),
      )
      @avatar_source = optional_path(environment.fetch("RAYCAST_AVATAR_SRC", nil))
      @release_api = URI(
        environment.fetch(
          "RAYCAST_RELEASE_API",
          "https://x.raycast-releases.com/releases/latest",
        ),
      )
      unless @release_api.is_a?(URI::HTTP) && @release_api.host
        raise Error, "Raycast release API must use HTTP(S): #{@release_api}"
      end

      @lock_file = path(
        environment.fetch(
          "RAYCAST_LOCK_FILE",
          Pathname(Dir.tmpdir)/"#{PROGRAM_NAME}-#{Process.uid}.lock",
        ),
      )
    rescue URI::InvalidURIError => e
      raise Error, "invalid Raycast release API URL: #{e.message}"
    end

    private

    def path(value)
      Pathname(value).expand_path.freeze
    end

    def optional_path(value)
      path(value) if value
    end
  end

  # Owns Raycast installation, local database configuration, and lifecycle.
  class Manager
    WAIT_TIMEOUT = 30
    WAIT_INTERVAL = 1

    def initialize(
      configuration: Configuration.new
    )
      @configuration = configuration
    end

    def with_lock
      @configuration.lock_file.dirname.mkpath
      @configuration.lock_file.open(
        File::RDWR | File::CREAT,
        0o600,
      ) do |lock|
        lock.flock(File::LOCK_EX)
        yield
      end
    end

    def install_latest(force: false)
      installed_version = app_version(@configuration.app)
      release = latest_release(current_version: force ? nil : installed_version)
      unless release
        raise Error, "Raycast release API reported an absent app as current" unless installed_version

        log "Raycast #{installed_version} is current"
        return false
      end
      if !force && installed_version && installed_version >= release.version
        log "Raycast #{installed_version} is current"
        return false
      end

      Dir.mktmpdir("raycast-") do |directory|
        root = Pathname(directory)
        image = root/"Raycast.dmg"
        mount = root/"mount"
        mount.mkpath
        log "downloading Raycast #{release.version}"
        download(release.uri, image)
        verify_dmg_checksum(image, release.checksum)
        system(
          "/usr/bin/hdiutil",
          "verify",
          image.to_s,
          out:       File::NULL,
          err:       File::NULL,
          exception: true,
        )
        attached = false
        begin
          system(
            "/usr/bin/hdiutil",
            "attach",
            image.to_s,
            "-nobrowse",
            "-readonly",
            "-mountpoint",
            mount.to_s,
            out:       File::NULL,
            err:       File::NULL,
            exception: true,
          )
          attached = true
          install_app(mount/"#{APP_NAME}.app", force:)
        ensure
          if attached
            system(
              "/usr/bin/hdiutil",
              "detach",
              mount.to_s,
              out: File::NULL,
              err: File::NULL,
            )
          end
        end
      end
      true
    end

    def configure(if_present: false)
      require_directory(@configuration.app)
      require_file(@configuration.data_addon)
      profile = load_profile(if_present:)
      return false unless profile

      require_file(@configuration.keydump_hook)
      require_file(@configuration.database_cli)
      require_file(@configuration.disable_ai_cli)
      node, key_file = extract_key
      avatar = ensure_avatar(profile)
      current_user = profile.current_user.dup
      if avatar
        current_user["image"] = file_url(avatar)
        current_user["avatar"] = file_url(avatar)
      end
      environment = {
        "RAYCAST_APP_SUPPORT" => @configuration.app_support.to_s,
        "RAYCAST_DATA_ADDON"  => @configuration.data_addon.to_s,
        "RAYCAST_KEY_FILE"    => key_file.to_s,
      }
      profile_updated = system(
        environment,
        node.to_s,
        @configuration.database_cli.to_s,
        "profile",
        "apply",
        JSON.generate(current_user),
        JSON.generate(profile.oauth_token),
      )
      raise Error, "Raycast profile database update failed" unless profile_updated

      unless profile.command_aliases.empty?
        aliases_updated = system(
          environment,
          node.to_s,
          @configuration.database_cli.to_s,
          "aliases",
          "apply",
          JSON.generate(profile.command_aliases),
        )
        raise Error, "Raycast command-alias database update failed" unless aliases_updated
      end

      ai_disabled = system(
        environment,
        node.to_s,
        @configuration.disable_ai_cli.to_s,
      )
      raise Error, "Raycast AI disable failed" unless ai_disabled

      system "/usr/bin/open", @configuration.app.to_s, exception: true
      log "Raycast configured and started"
      true
    end

    def refresh(force: false)
      install_latest(force:)
      configure(if_present: true)
    end

    def installed_version
      app_version(@configuration.app)
    end

    def latest_release(current_version: nil)
      endpoint = @configuration.release_api.dup
      endpoint.query = URI.encode_www_form(
        "platform"     => "macos",
        "architecture" => "arm64",
        "version"      => (current_version || Gem::Version.new("0.0.0.0")).to_s,
      )
      response_status = nil
      response_body = URI.open(
        endpoint,
        "Accept" => "application/json",
        "User-Agent" => USER_AGENT,
        open_timeout: HTTP_OPEN_TIMEOUT,
        read_timeout: HTTP_READ_TIMEOUT,
      ) do |response|
        response_status = response.status.first

        response.read unless response_status == "204"
      end
      return if response_status == "204"

      payload = JSON.parse(response_body)
      version = parse_version(payload.fetch("version"))
      download_url = payload.fetch("download_url")
      match = RELEASE_URL_PATTERN.match(download_url)
      raise Error, "Raycast release API returned an unexpected Apple Silicon DMG URL" unless match
      unless parse_version(match[1]) == version
        raise Error, "Raycast release API returned mismatched release and download versions"
      end

      Release.new(
        uri:      URI(download_url),
        version:,
        checksum: parse_dmg_checksum(payload["checksum"]),
      )
    rescue JSON::ParserError, KeyError, TypeError, URI::InvalidURIError => e
      raise Error, "invalid response from the Raycast release API: #{e.message}"
    rescue IOError,
           OpenURI::HTTPError,
           OpenSSL::SSL::SSLError,
           SocketError,
           SystemCallError,
           Timeout::Error => e
      raise Error, "could not read the Raycast release API: #{e.message}"
    end

    def file_url(path)
      escaped = URI::DEFAULT_PARSER.escape(Pathname(path).expand_path.to_s)
      URI::File.build(path: escaped).to_s
    end

    private

    def install_app(source, force: false)
      source = Pathname(source).expand_path
      source_version = validate_app(source)
      installed_version = app_version(@configuration.app)
      if !force && installed_version && installed_version >= source_version
        log "keeping Raycast #{installed_version} in #{@configuration.app}"
        return
      end

      destination = @configuration.app
      destination.dirname.mkpath
      transaction = Pathname(
        Dir.mktmpdir(
          ".#{destination.basename}.install-",
          destination.dirname.to_s,
        ),
      )
      staging = transaction/"staging.app"
      backup = transaction/"backup.app"
      system "/usr/bin/ditto", source.to_s, staging.to_s, exception: true
      validate_app(staging)
      system(
        "/usr/bin/killall",
        APP_NAME,
        out: File::NULL,
        err: File::NULL,
      )

      File.rename(destination, backup) if path_exists?(destination)
      begin
        File.rename(staging, destination)
      rescue StandardError
        File.rename(backup, destination) if path_exists?(backup) && !path_exists?(destination)
        raise
      end
      log "installed Raycast #{source_version} in #{destination}"
    ensure
      if defined?(backup) && path_exists?(backup) && !path_exists?(@configuration.app)
        File.rename(backup, @configuration.app)
      end
      remove_path(transaction) if defined?(transaction)
    end

    def validate_app(app)
      require_directory(app)
      plist = require_file(app/"Contents/Info.plist")
      executable = require_file(app/"Contents/MacOS/#{APP_NAME}")
      raise Error, "Raycast executable is not executable: #{executable}" unless executable.executable?

      bundle_id = plist_value(plist, "CFBundleIdentifier")
      raise Error, "unexpected Raycast bundle identifier: #{bundle_id.inspect}" unless bundle_id == EXPECTED_BUNDLE_ID

      app_version(app) || raise(Error, "Raycast app is missing its version")
    end

    def app_version(app)
      plist = Pathname(app)/"Contents/Info.plist"
      return unless plist.file?

      parse_version(plist_value(plist, "CFBundleShortVersionString"))
    end

    def plist_value(plist, key)
      stdout, stderr, status = Open3.capture3(
        "/usr/bin/plutil",
        "-extract",
        key,
        "raw",
        "-o",
        "-",
        plist.to_s,
      )
      return stdout.strip if status.success?

      details = stderr.strip
      details = "plutil failed with exit #{status.exitstatus}" if details.empty?
      raise Error, details
    end

    def parse_version(value)
      Gem::Version.new(value.to_s)
    rescue ArgumentError => e
      raise Error, "invalid Raycast version #{value.inspect}: #{e.message}"
    end

    def parse_dmg_checksum(value)
      return if value.nil?

      checksum = value.to_s
      raise Error, "Raycast release API returned an unexpected checksum" unless checksum.match?(DMG_CHECKSUM_PATTERN)

      checksum.downcase
    end

    def verify_dmg_checksum(image, checksum)
      return unless checksum

      actual = Digest::MD5.file(image).hexdigest
      return if actual.casecmp?(checksum)

      raise Error, "downloaded Raycast DMG checksum mismatch"
    end

    def node_directory
      runtime = @configuration.app_support/"node/runtime"
      unless runtime.directory?
        log "starting Raycast once to initialize its Node runtime"
        system "/usr/bin/open", @configuration.app.to_s, exception: true
        wait_until("Raycast Node runtime", timeout: WAIT_TIMEOUT) { runtime.directory? }
      end

      candidates = runtime.glob("node-v*/bin").select do |directory|
        (directory/"node").file? || (directory/"node.real").file?
      end
      raise Error, "Raycast Node runtime not found under #{runtime}" if candidates.empty?

      candidates.max_by do |directory|
        parse_version(directory.parent.basename.to_s.delete_prefix("node-v"))
      end
    end

    def extract_key
      directory = node_directory
      hook = directory/".keydump.cjs"
      key_file = directory/".raycast-key-cache"
      node = directory/"node"
      real = directory/"node.real"
      restore_node(node, real, hook) if real.file?

      if read_key(key_file)
        log "using cached Raycast DB key: #{key_file}"
        return [node, key_file]
      end

      require_file(@configuration.keydump_hook)
      hook.write("require(#{@configuration.keydump_hook.to_s.to_json});\n")
      system(
        "/usr/bin/killall",
        APP_NAME,
        out: File::NULL,
        err: File::NULL,
      )
      File.rename(node, real)
      begin
        write_node_wrapper(node, real, hook, key_file)
        log "extracting Raycast DB key"
        system "/usr/bin/open", @configuration.app.to_s, exception: true
        wait_until("Raycast DB key", timeout: WAIT_TIMEOUT) { key_file.file? }
        system(
          "/usr/bin/killall",
          APP_NAME,
          out: File::NULL,
          err: File::NULL,
        )
        sleep 2
        key = read_key(key_file)
        raise Error, "failed to read captured Raycast DB key" unless key

        log "Raycast DB key extracted (#{key.bytesize} bytes)"
      ensure
        restore_node(node, real, hook)
      end
      [node, key_file]
    end

    def read_key(path)
      return unless path.file?

      path.chmod(0o600)
      value = path.read.strip
      if value.empty?
        FileUtils.rm_f(path)
        return
      end

      value
    end

    def restore_node(node, real, hook)
      return unless real.file?

      FileUtils.rm_f(node)
      File.rename(real, node)
      FileUtils.rm_f(hook)
    end

    def write_node_wrapper(node, real, hook, key_file)
      node.write <<~SH
        #!/bin/sh
        export RAYCAST_KEYDUMP_FILE=#{key_file.to_s.shellescape}
        exec #{real.to_s.shellescape} --require #{hook.to_s.shellescape} "$@"
      SH
      node.chmod(0o755)
    end

    def load_profile(if_present: false)
      path = @configuration.profile_file
      unless path.file?
        if if_present
          warning "profile not found; skipping configuration: #{path}"
          return
        end
        raise Error, "required file not found: #{path}"
      end

      data = JSON.load_file(path)
      current_user = require_object(data, "current_user")
      oauth_token = require_object(data, "oauth_token")
      require_nonempty_string(current_user, "id", "current_user")
      require_nonempty_string(current_user, "name", "current_user")
      require_nonempty_string(oauth_token, "access_token", "oauth_token")
      aliases = data.fetch("command_aliases", [])
      raise Error, "command_aliases must be an array of objects" unless aliases.is_a?(Array) && aliases.all?(Hash)

      Profile.new(
        current_user:,
        oauth_token:,
        avatar_url:      data.fetch("avatar_url", ""),
        command_aliases: aliases,
      )
    rescue JSON::ParserError, KeyError => e
      raise Error, "invalid Raycast profile: #{e.message}"
    end

    def require_object(object, key)
      value = object.fetch(key)
      raise Error, "#{key} must be an object" unless value.is_a?(Hash)

      value
    end

    def require_nonempty_string(object, key, context)
      value = object.fetch(key)
      return value if value.is_a?(String) && !value.empty?

      raise Error, "#{context}.#{key} must be a non-empty string"
    end

    def ensure_avatar(profile)
      @configuration.app_support.mkpath
      destination = @configuration.app_support/"avatar.png"
      source_path = @configuration.avatar_source
      if source_path&.file?
        render_avatar(source_path, destination)
        log "avatar resized from #{source_path}"
        return destination
      end

      if profile.avatar_url.to_s.empty?
        warning "profile is missing avatar_url; continuing without an avatar"
        return destination if destination.file?

        return
      end

      Dir.mktmpdir("raycast-avatar-") do |directory|
        source = Pathname(directory)/"avatar"
        download(URI(profile.avatar_url), source)
        render_avatar(source, destination)
      end
      log "avatar downloaded and resized from #{profile.avatar_url}"
      destination
    rescue Error, URI::InvalidURIError => e
      warning "failed to prepare Raycast avatar: #{e.message}"
      destination if destination&.file?
    end

    def render_avatar(source, destination)
      destination.dirname.mkpath
      Tempfile.create(
        [".#{destination.basename}.", ".png"],
        destination.dirname.to_s,
      ) do |temporary|
        temporary.close
        system(
          "/usr/bin/sips",
          "--resampleHeightWidthMax",
          "256",
          "--setProperty",
          "format",
          "png",
          source.to_s,
          "--out",
          temporary.path,
          out:       File::NULL,
          err:       File::NULL,
          exception: true,
        )
        File.rename(temporary.path, destination)
      end
    end

    def wait_until(description, timeout:)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        return true if yield

        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        break if remaining <= 0

        sleep [WAIT_INTERVAL, remaining].min
      end
      raise Error, "timed out waiting for #{description}"
    end

    def download(uri, destination)
      uri = URI(uri.to_s)
      raise Error, "unsupported download URL: #{uri}" unless uri.is_a?(URI::HTTP) && uri.host

      destination = Pathname(destination)
      destination.dirname.mkpath
      Tempfile.create(
        [".#{destination.basename}.", ".download"],
        destination.dirname.to_s,
      ) do |temporary|
        temporary.binmode
        URI.open(
          uri,
          "Accept" => "*/*",
          "User-Agent" => USER_AGENT,
          open_timeout: HTTP_OPEN_TIMEOUT,
          read_timeout: HTTP_READ_TIMEOUT,
        ) do |response|
          IO.copy_stream(response, temporary)
        end
        temporary.flush
        temporary.fsync
        temporary.close
        File.rename(temporary.path, destination)
      end
      destination
    rescue IOError,
           OpenSSL::SSL::SSLError,
           SocketError,
           SystemCallError,
           Timeout::Error => e
      raise Error, "download failed for #{uri}: #{e.message}"
    end

    def require_file(path)
      raise Error, "required file not found: #{path}" unless path.file?

      path
    end

    def require_directory(path)
      raise Error, "required directory not found: #{path}" unless path.directory?

      path
    end

    def path_exists?(path)
      path.exist? || path.symlink?
    end

    def remove_path(path)
      return unless path && path_exists?(path)

      FileUtils.rm_rf(path)
    end

    def log(message)
      warn "#{PROGRAM_NAME}: #{message}"
    end

    def warning(message)
      warn "#{PROGRAM_NAME}: warning: #{message}"
    end
  end

  # Parses the small subcommand interface with Ruby's standard OptionParser.
  class CLI
    def initialize(manager: Manager.new, output: $stdout)
      @manager = manager
      @output = output
    end

    def run(arguments)
      command = arguments.shift
      case command
      when "install"
        force = false
        parser = OptionParser.new do |options|
          options.banner = "Usage: #{PROGRAM_NAME} install [--force]"
          options.on("--force", "Replace the app even when it is current") do
            force = true
          end
          options.on("-h", "--help", "Show this help") do
            @output.puts options
            return 0
          end
        end
        parser.parse!(arguments)
        reject_arguments(arguments)

        @manager.with_lock { @manager.install_latest(force:) }
      when "configure"
        if_present = false
        parser = OptionParser.new do |options|
          options.banner = "Usage: #{PROGRAM_NAME} configure [--if-present]"
          options.on("--if-present", "Skip when the profile is absent") do
            if_present = true
          end
          options.on("-h", "--help", "Show this help") do
            @output.puts options
            return 0
          end
        end
        parser.parse!(arguments)
        reject_arguments(arguments)

        @manager.with_lock do
          @manager.configure(if_present:)
        end
      when "refresh"
        force = false
        parser = OptionParser.new do |options|
          options.banner = "Usage: #{PROGRAM_NAME} refresh [--force]"
          options.on("--force", "Replace the app even when it is current") do
            force = true
          end
          options.on("-h", "--help", "Show this help") do
            @output.puts options
            return 0
          end
        end
        parser.parse!(arguments)
        reject_arguments(arguments)

        @manager.with_lock { @manager.refresh(force:) }
      when "version"
        reject_arguments(arguments)
        @output.puts(@manager.installed_version || "not installed")
      when "help", "--help", "-h", nil
        reject_arguments(arguments)
        @output.puts help
      else
        raise Error, "unknown command: #{command}"
      end
      0
    rescue OptionParser::ParseError => e
      raise Error, e.message
    end

    def help
      <<~TEXT
        Usage: #{PROGRAM_NAME} <command> [options]

        Commands:
          install [--force]      Download and install the latest Raycast release
          configure             Apply the local profile, aliases, and AI-disable policy
          refresh [--force]      Install latest, then apply local configuration
          version               Print the installed Raycast version
      TEXT
    end

    def reject_arguments(arguments)
      return if arguments.empty?

      raise OptionParser::InvalidArgument, arguments.join(" ")
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    exit Raycast::CLI.new.run(ARGV)
  rescue Raycast::Error,
         SystemCallError,
         RuntimeError => e
    warn "#{Raycast::PROGRAM_NAME}: error: #{e.message}"
    exit 1
  end
end
