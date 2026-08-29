# frozen_string_literal: true

require "json"

class JjPatched < Formula
  tap_root = Pathname(__dir__).parent
  pins = JSON.load_file(tap_root/"npins/sources.json").fetch("pins")
  jj = pins.fetch("jj")
  archive = pins.fetch("jj_archive")
  patches_tap = Tap.fetch("4evy", "patches")
  raise "Tap 4evy/patches before installing jj-patched" unless patches_tap.installed?

  manifest = JSON.load_file(patches_tap.path/"stacks/jj/stack.json")
  stack_revision = manifest.fetch("source").fetch("revision")
  result_tree = manifest.fetch("result").fetch("tree").fetch("oid")
  raise "The jj source pin does not match the 4evy/patches stack" if stack_revision != jj.fetch("revision")

  digest = archive.fetch("hash").delete_prefix("sha256-").unpack1("m0").unpack1("H*")

  desc "Jujutsu build with the 4evy patch stack"
  homepage "https://github.com/jj-vcs/jj"
  url archive.fetch("url")
  version "0.44.0-head-#{result_tree[0, 8]}"
  sha256 digest
  license "Apache-2.0"
  depends_on "rust" => :build

  conflicts_with "jj", because: "both install a jj binary"

  def install
    patch_dir = Tap.fetch("4evy", "patches").path/"stacks/jj/patches"
    patches = (patch_dir/"series").readlines(chomp: true).map { |name| patch_dir/name }
    odie "jj patch series is empty: #{patch_dir}" if patches.empty?

    system "git", "apply", *patches
    system "cargo", "install", "--bin", "jj", *std_cargo_args(path: "cli")

    generate_completions_from_executable(bin/"jj", shell_parameter_format: :clap)
    system bin/"jj", "util", "install-man-pages", man
  end
end
