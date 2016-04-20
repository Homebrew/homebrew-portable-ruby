module PortableFormulaInstall
  def install
    if OS.mac? && OS::Mac.version > :leopard
      opoo <<-EOS.undent
        You are building portable Ruby on #{OS::Mac.version}.
        As result, Ruby interpreter won't be able to work for OS X at lower version.
        It's recommended to build this formula on OS X Leopard.
      EOS
    end

    super

    if OS.mac?
      fix_dylibs!
    end
  end
end

class PortableFormula < Formula
  def self.inherited(subclass)
    subclass.class_eval do
      keg_only "Portable formula is keg-only."

      option "without-universal", "Don't build a universal binary" if OS.mac?

      prepend PortableFormulaInstall
    end
  end

  def archs
    if build.with? "universal"
      Hardware::CPU.universal_archs
    elsif OS::Mac.prefer_64_bit?
      [Hardware::CPU.arch_64_bit]
    else
      [Hardware::CPU.arch_32_bit]
    end
  end

  def dylibs_map
    system_dylibs = {}
    broken_dylibs = {}
    brewed_dylibs = {}

    Keg.new(prefix).find do |file|
      next if file.symlink? || file.directory?
      next unless file.dylib? || file.mach_o_executable? || file.mach_o_bundle?
      file.dynamically_linked_libraries.each do |dylib|
        next if dylib =~ /^@(loader_|executable_|r)path/

        begin
          Keg.for Pathname.new(dylib)
        rescue NotAKegError
          system_dylibs[file] ||= []
          system_dylibs[file] << dylib
        rescue Errno::ENOENT
          broken_dylibs[file] ||= []
          broken_dylibs[file] << dylib
        else
          brewed_dylibs[file] ||= []
          brewed_dylibs[file] << dylib
        end
      end
    end

    [system_dylibs, broken_dylibs, brewed_dylibs]
  end

  def fix_dylibs!
    _system_dylibs, broken_dylibs, brewed_dylibs = dylibs_map

    unless broken_dylibs.empty?
      error_msg = "Missing libraries found:\n"
      error_msg += broken_dylibs.map do |file, dylibs|
        " - From #{file.relative_path_from(prefix)}:\n" + \
        dylibs.sort.map { |dylib| "   * #{dylib}" }.join("\n")
      end.join("\n")
      raise error_msg
    end

    brewed_dylibs.each do |file, dylibs|
      dylibs.each do |dylib|
        new_dylib = dylib.relative_path_from(file.dirname)
        file.ensure_writable do
          if file.dylib? || file.mach_o_bundle?
            system "install_name_tool", "-change", dylib, "@loader_path/#{new_dylib}", file
          elsif file.mach_o_executable?
            system "install_name_tool", "-change", dylib, "@executable_path/#{new_dylib}", file
          end
        end
      end
    end
  end
end
