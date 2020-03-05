require "cli/parser"

module Homebrew
  include FileUtils

  module_function

  def portable_package_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `portable-package` <formulae>

        Build and package portable formulae.
      EOS
      switch "--no-uninstall-deps",
             description: "Don't uninstall all dependencies of portable formulae before testing."
      switch "--no-rebuild",
             description: "Remove `rebuild`."
      switch "--keep-old",
             description: "Attempt to keep `rebuild` at its original value."
      switch "--write",
             description: "Write the changes to the formula file."
      switch "--no-commit",
             description: "Don't commit changes to the formula file."
      conflicts "--no-rebuild", "--keep-old"
      min_named :formula
    end
  end

  def portable_package
    portable_package_args.parse

    if !Homebrew.args.write? && Homebrew.args.no_commit?
      raise UsageError, "--no-commit requires --write!"
    end

    ENV["HOMEBREW_DEVELOPER"] = "1"
    ENV["HOMEBREW_BUILD_BOTTLE"] = "1" if OS.linux?

    Homebrew.args.named.each do |name|
      name = "portable-#{name}" unless name.start_with? "portable-"
      begin
        deps = Utils.popen_read("brew", "deps", "--include-build", name).split("\n")

        # Avoid installing glibc. Bottles depend on glibc.
        safe_system "brew", "install", "-s", *deps if OS.linux?

        safe_system "brew", "install", "--build-bottle", name
        unless Homebrew.args.no_uninstall_deps?
          safe_system "brew", "uninstall", "--force", "--ignore-dependencies", *deps
        end
        safe_system "brew", "test", name
        puts "Linkage information:"
        safe_system "brew", "linkage", name
        bottle_args = %w[--skip-relocation]
        bottle_args << "--no-rebuild" if Homebrew.args.no_rebuild?
        bottle_args << "--keep-old" if Homebrew.args.keep_old?
        bottle_args << "--write" if Homebrew.args.write?
        bottle_args << "--no-commit" if Homebrew.args.no_commit?
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
  end
end
