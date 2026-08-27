#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "pathname"
require "shellwords"
require "set"
require "tempfile"
require "tmpdir"

module Records
  class Error < StandardError; end

  FORMAT_VERSION = 1
  COLLECTIONS = %w[t0].freeze
  COLLECTION_SET = COLLECTIONS.to_set.freeze
  METADATA_KEYS = {
    "t0" => Set["executable", "paths", "private", "render", "systems"].freeze,
  }.freeze
  FORBIDDEN_PATH_COMPONENTS = Set[".", ".."].freeze
  SUPPORTED_SYSTEMS = Set["darwin", "linux"].freeze

  class Vault
    def initialize(environment: ENV)
      @environment = environment
      repository = environment.fetch("RECORDS_REPOSITORY") { Pathname(__dir__).parent }
      @repository = Pathname(repository).realpath
      vault = environment.fetch("RECORDS_FILE") { @repository/"secrets/records.yaml" }
      @vault = Pathname(vault).expand_path
      @sops = environment.fetch("RECORDS_SOPS", "sops")
    end

    def unpack(destination)
      root, created = prepare_destination(destination)
      collections = decrypt_collections
      write_workspace(root, collections)
      puts "unpacked #{record_count(collections)} records into #{root}"
      root
    rescue StandardError
      if root&.directory?
        if created
          FileUtils.remove_entry_secure(root)
        elsif !Dir.empty?(root)
          warn "records: protected workspace retained at #{root}"
        end
      end
      raise
    end

    def pack(source)
      root = existing_workspace(source)
      collections = read_workspace(root)
      current = decrypt_collections
      if collections == current
        puts "records unchanged"
        return false
      end

      encoded_items = COLLECTIONS.to_h do |collection|
        [collection, JSON.generate(collections.fetch(collection), sort_keys: true)]
      end
      replace_vault(encoded_items, collections)

      puts "packed #{record_count(collections)} records into the encrypted vault"
      true
    end

    def check(source = nil)
      collections = source ? read_workspace(existing_workspace(source)) : decrypt_collections
      puts "validated #{record_count(collections)} records"
      true
    end

    def edit(collection = nil, index = nil)
      validate_edit_target(collection, index)
      workspace = Pathname(Dir.mktmpdir("dotfiles-records-"))
      completed = false
      begin
        collections = decrypt_collections
        write_workspace(workspace, collections)
        target = editor_target(workspace, collection, index)
        editor_name = @environment.fetch("VISUAL") { @environment.fetch("EDITOR", "") }
        editor = Shellwords.shellsplit(editor_name)
        raise Error, "VISUAL or EDITOR must name an editor" if editor.empty?

        puts "editing protected workspace #{workspace}"
        system(*editor, target.to_s, exception: true)

        pack(workspace)
        completed = true
      ensure
        if completed
          FileUtils.remove_entry_secure(workspace)
        elsif workspace.directory?
          warn "records: protected workspace retained at #{workspace}"
        end
      end
    end

    private

    def decrypt_collections(vault = @vault)
      output = run_sops(
        "decrypt",
        "--input-type",
        "yaml",
        "--output-type",
        "json",
        "--extract",
        '["items"]',
        vault.to_s,
      )
      items = JSON.parse(output)
      raise Error, "encrypted manifest items must be an object" unless items.is_a?(Hash)

      collections = COLLECTIONS.to_h do |collection|
        encoded = items.fetch(collection)
        raise Error, "encrypted #{collection} manifest must be a string" unless encoded.is_a?(String)

        [collection, JSON.parse(encoded)]
      end
      validate_collections(collections)
      collections
    rescue KeyError => e
      raise Error, "encrypted manifest is missing a collection (#{e.message})"
    rescue JSON::ParserError => e
      raise Error, "encrypted manifest is not valid JSON (#{e.message})"
    end

    def run_sops(*arguments, stdin_data: "")
      environment = {}
      config = @repository/".sops.yaml"
      environment["SOPS_CONFIG"] = config.to_s if @environment["SOPS_CONFIG"].to_s.empty? && config.file?
      helper = @repository/"dotfiles/dot_local/bin/executable_sops-age-key-1password"
      if @environment["SOPS_AGE_KEY_CMD"].to_s.empty? && RUBY_PLATFORM.include?("darwin") && helper.executable?
        environment["SOPS_AGE_KEY_CMD"] = helper.to_s
      end
      stdout, stderr, status = Open3.capture3(environment, @sops, *arguments, stdin_data:)
      return stdout if status.success?

      details = stderr.strip
      details = stdout.strip if details.empty?
      message = "sops command failed"
      message = "#{message}: #{details}" unless details.empty?
      raise Error, message
    end

    def replace_vault(encoded_items, collections)
      mode = @vault.stat.mode & 0o777
      replace_atomically(@vault, mode) do |temporary|
        IO.copy_stream(@vault, temporary)
        temporary.close
        run_sops(
          "--filename-override",
          @vault.to_s,
          "set",
          "--input-type",
          "yaml",
          "--output-type",
          "yaml",
          "--idempotent",
          "--value-stdin",
          temporary.path,
          '["items"]',
          stdin_data: JSON.generate(encoded_items),
        )
        unless decrypt_collections(Pathname(temporary.path)) == collections
          raise Error, "encrypted vault did not round-trip"
        end
      end
    end

    def replace_atomically(path, mode)
      Tempfile.create(["#{path.basename}.tmp.", ""], path.dirname) do |temporary|
        temporary.binmode
        yield temporary
        temporary.flush unless temporary.closed?
        temporary.close unless temporary.closed?
        File.chmod(mode, temporary.path)
        File.open(temporary.path, "rb", &:fsync)
        File.rename(temporary.path, path)
      end
    end

    def prepare_destination(destination)
      path = Pathname(destination).expand_path
      if path.exist? || path.symlink?
        raise Error, "workspace must be an empty directory: #{path}" unless path.directory? && Dir.empty?(path)
        raise Error, "workspace must not be a symlink: #{path}" if path.symlink?

        return [existing_workspace(path), false]
      end

      raise Error, "workspace parent does not exist: #{path.parent}" unless path.parent.directory?

      resolved = path.parent.realpath/path.basename
      ensure_outside_repository(resolved)
      Dir.mkdir(resolved, 0o700)
      [resolved, true]
    end

    def existing_workspace(source)
      path = Pathname(source).expand_path
      raise Error, "workspace is not a directory: #{path}" unless path.directory?
      raise Error, "workspace must not be a symlink: #{path}" if path.symlink?

      path = path.realpath
      ensure_outside_repository(path)
      mode = path.stat.mode & 0o777
      raise Error, "workspace permissions must not grant group or other access" unless mode.nobits?(0o077)

      path
    end

    def ensure_outside_repository(path)
      return unless path.ascend.include?(@repository)

      raise Error, "plaintext workspaces must be outside the repository"
    end

    def write_workspace(root, collections)
      format_json = JSON.pretty_generate(
        { "version" => FORMAT_VERSION, "collections" => COLLECTIONS },
        sort_keys: true,
      )
      write_private(
        root/"format.json",
        "#{format_json}\n",
      )
      COLLECTIONS.each do |collection|
        collection_root = root/collection
        collection_root.mkdir(0o700)
        collections.fetch(collection).each_with_index do |record, index|
          record_root = collection_root/format("%03d", index)
          record_root.mkdir(0o700)
          metadata = JSON.pretty_generate(record.except("body"), sort_keys: true)
          write_private(record_root/"metadata.json", "#{metadata}\n")
          write_private(record_root/"body", record.fetch("body"))
        end
      end
    end

    def write_private(path, content)
      path.write(content, mode: "wx", perm: 0o600)
    end

    def read_workspace(root)
      assert_entries(root, ["format.json", *COLLECTIONS])
      format = parse_json_file(root/"format.json", "workspace format")
      expected_format = { "version" => FORMAT_VERSION, "collections" => COLLECTIONS }
      raise Error, "unsupported workspace format" unless format == expected_format

      collections = COLLECTIONS.to_h do |collection|
        collection_root = root/collection
        raise Error, "missing collection directory: #{collection}" unless collection_root.directory?
        raise Error, "collection directory must not be a symlink: #{collection}" if collection_root.symlink?

        directories = collection_root.children.sort_by(&:basename)
        records = directories.each_with_index.map do |record_root, index|
          expected_name = format("%03d", index)
          unless record_root.directory? && !record_root.symlink? && record_root.basename.to_s == expected_name
            raise Error, "#{collection} record directories must be contiguous and zero-padded"
          end

          assert_entries(record_root, %w[body metadata.json])
          metadata_label = "#{collection} record #{expected_name} metadata"
          metadata = parse_json_file(record_root/"metadata.json", metadata_label)
          raise Error, "#{metadata_label} must be an object" unless metadata.is_a?(Hash)

          body_path = record_root/"body"
          raise Error, "#{collection} record #{expected_name} body must be a regular file" unless body_path.file?
          raise Error, "#{collection} record #{expected_name} body must not be a symlink" if body_path.symlink?

          metadata.merge("body" => body_path.binread.force_encoding(Encoding::UTF_8))
        end
        [collection, records]
      end
      validate_collections(collections)
      collections
    end

    def parse_json_file(path, label)
      raise Error, "missing #{label}" unless path.file?
      raise Error, "#{label} must not be a symlink" if path.symlink?

      JSON.load_file(path)
    rescue JSON::ParserError => e
      raise Error, "#{label} is not valid JSON (#{e.message})"
    end

    def assert_entries(directory, expected)
      actual = directory.children.to_set { |path| path.basename.to_s }
      return if actual == expected.to_set

      raise Error, "unexpected files in protected workspace: #{directory}"
    end

    def validate_collections(collections)
      raise Error, "manifest must contain exactly t0" unless collections.keys.to_set == COLLECTION_SET

      collections.each do |collection, records|
        raise Error, "#{collection} manifest must be an array" unless records.is_a?(Array)

        records.each_with_index { |record, index| validate_record(collection, record, index) }
      end
      validate_unique_paths(collections)
    end

    def validate_record(collection, record, index)
      label = "#{collection} record #{format('%03d', index)}"
      raise Error, "#{label} must be an object" unless record.is_a?(Hash)

      expected_keys = METADATA_KEYS.fetch(collection) | ["body"]
      raise Error, "#{label} has unexpected fields" unless record.keys.to_set == expected_keys

      body = record.fetch("body")
      raise Error, "#{label} body must be UTF-8 text" unless body.is_a?(String) && body.valid_encoding?

      validate_target_record(record, label)
    end

    def validate_target_record(record, label)
      paths = record.fetch("paths")
      systems = record.fetch("systems")
      unless valid_path_array?(paths) && paths.to_set.size == paths.size
        raise Error, "#{label} paths must be unique safe relative paths"
      end

      valid_systems = systems.is_a?(Array) && systems.to_set.subset?(SUPPORTED_SYSTEMS)
      unless valid_systems && systems.to_set.size == systems.size
        raise Error, "#{label} systems must contain unique supported systems"
      end

      %w[private executable render].each do |field|
        raise Error, "#{label} #{field} must be boolean" unless [true, false].include?(record.fetch(field))
      end
    end

    def valid_path_array?(paths)
      paths.is_a?(Array) && !paths.empty? && paths.all? { |path| valid_relative_path?(path) }
    end

    def valid_relative_path?(value)
      return false unless value.is_a?(String) && !value.empty? && !value.include?("\0")

      path = Pathname(value)
      path.relative? && path == path.cleanpath && path.each_filename.none? do |component|
        FORBIDDEN_PATH_COMPONENTS.include?(component)
      end
    end

    def validate_unique_paths(collections)
      target_paths = collections.fetch("t0").flat_map { |record| record.fetch("paths") }
      raise Error, "t0 destinations must be unique" unless target_paths.to_set.size == target_paths.size
    end

    def validate_edit_target(collection, index)
      raise Error, "an index requires a collection" if index && !collection
      raise Error, "unknown collection: #{collection}" if collection && !COLLECTIONS.include?(collection)
      return unless index

      parsed_index = Integer(index, 10, exception: false)
      raise Error, "record index must be a non-negative integer" unless parsed_index && !parsed_index.negative?
    end

    def editor_target(workspace, collection, index)
      return workspace unless collection
      return workspace/collection unless index

      target = workspace/collection/format("%03d", Integer(index, 10))
      raise Error, "record does not exist" unless target.directory?

      target
    end

    def record_count(collections)
      collections.values.sum(&:length)
    end
  end

  module_function

  def usage
    <<~TEXT
      Usage: records.rb <command> [arguments]

      Commands:
        unpack DIRECTORY           Decrypt records into a protected workspace
        pack DIRECTORY             Validate and re-encrypt a workspace
        check [DIRECTORY]          Validate the vault or a workspace
        edit [COLLECTION [INDEX]]  Edit all records or one numbered record
    TEXT
  end

  def main(arguments)
    vault = Vault.new
    case arguments
    in ["unpack", destination]
      vault.unpack(destination)
    in ["pack", source]
      vault.pack(source)
    in ["check"]
      vault.check
    in ["check", source]
      vault.check(source)
    in ["edit"]
      vault.edit
    in ["edit", collection]
      vault.edit(collection)
    in ["edit", collection, index]
      vault.edit(collection, index)
    in [] | ["--help" | "-h" | "help"]
      puts usage
    else
      raise Error, "invalid arguments"
    end
    0
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    exit Records.main(ARGV)
  rescue Records::Error, RuntimeError, SystemCallError => e
    warn "records: error: #{e.message}"
    exit 1
  end
end
