# Build a portable Homebrew utility bottle.
#
# Usage: brew portable-package <formula> [formula...]

odie "Need to specify at least one portable formula!" if ARGV.empty?

if RUBY_VERSION.split(".").first.to_i < 2
  safe_system "brew", "install", "ruby"
  ENV["HOMEBREW_RUBY_PATH"] = "#{HOMEBREW_PREFIX}/bin/ruby"
end

ENV["HOMEBREW_PREFER_64_BIT"] = "1"
ENV["HOMEBREW_DEVELOPER"] = "1"

ARGV.named.each do |name|
  name = "portable-#{name}" unless name.start_with? "portable-"
  f = Formula[name]
  safe_system "brew", "install", "--build-bottle", name
  safe_system "brew uninstall --force $(brew deps --include-build #{name})"
  safe_system "brew", "test", name
  puts "Library linkage:"
  if OS.linux?
    puts Utils.popen_read "ldd", "#{f.bin}/#{name.gsub(/^portable-/, "")}"
  else
    puts Utils.popen_read "brew", "linkage", name
  end
  safe_system "brew", "bottle", "--skip-relocation", name
end
