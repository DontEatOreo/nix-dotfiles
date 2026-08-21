# frozen_string_literal: true

class JjPatched < Formula
  desc "Jujutsu build with native signing, redate, and shallow workflow patches"
  homepage "https://github.com/jj-vcs/jj"
  url "https://github.com/4evy/jj/archive/f53cd646445cf12eda3f7afebe7073d95fd34ac7.tar.gz"
  version "0.44.0-head-f53cd646"
  sha256 "26e71c301547910c6ab12a4f314687fd1e60948e6efb4fd505889ab32b4da64e"
  license "Apache-2.0"
  depends_on "rust" => :build

  conflicts_with "jj", because: "both install a jj binary"

  def install
    tap_root = Pathname(__dir__).parent
    patch_dir = tap_root/"packages/jj-patched/patches"
    patches = (patch_dir/"series").each_line(chomp: true).filter_map do |line|
      name = line.strip
      next if name.empty? || name.start_with?("#")

      patch_dir/name
    end
    odie "jj patch series is empty: #{patch_dir}" if patches.empty?
    odie "jj patch series contains a missing file" unless patches.all?(&:file?)

    patches.each do |patch|
      system "git", "apply", "--check", patch
      system "git", "apply", patch
    end
    # Cargo install does not build test targets; select the one shipped binary
    # so future auxiliary binaries do not lengthen this patched source build.
    system "cargo", "install", "--bin", "jj", *std_cargo_args(path: "cli")

    generate_completions_from_executable(bin/"jj", shell_parameter_format: :clap)
    system bin/"jj", "util", "install-man-pages", man
  end
end
