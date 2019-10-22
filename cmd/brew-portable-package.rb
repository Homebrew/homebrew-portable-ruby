#: `brew` `portable-package` [`--no-uninstall-deps`] [`--no-rebuild`|`--keep-old`] [`--write` [`--no-commit`]] <formulae>:
#:    Build and package portable formulae.
#:
#:    Unless `--no-uninstall-deps` is passed, all dependencies of portable
#:    formulae will be uninstalled before test. Useful for developing purpose.
#:
#:    If the formula specifies a rebuild version, it will be incremented in the
#:    generated DSL. Passing `--keep-old` will attempt to keep it at its
#:    original value, while `--no-rebuild` will remove it.
#:
#:    If `--write` is passed, write the changes to the formula file.
#:    A new commit will then be generated unless `--no-commit` is passed.

ENV["HOMEBREW_DEVELOPER"] = "1"
ENV["HOMEBREW_BUILD_BOTTLE"] = "1" if OS.linux?

include FileUtils # rubocop:disable Style/MixinUsage

BOTTLE_ARGS = %w[
  --keep-old
  --write
  --merge
  --no-commit
].freeze

ARGV.named.each do |name|
  name = "portable-#{name}" unless name.start_with? "portable-"
  begin
    deps = Utils.popen_read("brew", "deps", "--include-build", name).split("\n")

    # Avoid installing glibc. Bottles depend on glibc.
    safe_system "brew", "install", "-s", *deps if OS.linux?

    safe_system "brew", "install", "--build-bottle", name
    unless ARGV.include? "--no-uninstall-deps"
      safe_system "brew", "uninstall", "--force", "--ignore-dependencies", *deps
    end
    safe_system "brew", "test", name
    puts "Linkage information:"
    safe_system "brew", "linkage", name
    bottle_args = %w[--skip-relocation]
    bottle_args += ARGV.select { |arg| BOTTLE_ARGS.include? arg }
    safe_system "brew", "bottle", *bottle_args, name
    Pathname.glob("*.bottle*.tar.gz") do |bottle_filename|
      bottle_file = bottle_filename.realpath
      bottle_cache = HOMEBREW_CACHE/bottle_filename
      ln bottle_file, bottle_cache, force: true
    end
  rescue => e
    ofail e
  end
end

Pathname.glob("*.bottle*.tar.gz") do |bottle_filename|
  bottle_cache = HOMEBREW_CACHE/bottle_filename
  rm_f bottle_cache
end
