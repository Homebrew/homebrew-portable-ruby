module PortableFormulaMixin
  def install
    tag = Hardware::CPU.ppc? ? :tiger : :leopard
    if OS.mac? && OS::Mac.version > tag
      opoo <<-EOS.undent
        You are building portable formula on #{OS::Mac.version}.
        As result, formula won't be able to work for OS X at lower version.
        It's recommended to build this formula on OS X #{tag.capitalize}.
      EOS
    end

    if OS.linux?
      # reset Linuxbrew env, because we want to build formula against
      # libraries offered by system (CentOS docker) rather than Linuxbrew.
      ENV.delete "LDFLAGS"
      ENV.delete "LIBRARY_PATH"
      ENV.delete "LD_RUN_PATH"
      ENV.delete "LD_LIBRARY_PATH"
    end

    super
  end

  def test
    if OS.mac?
      assert_no_match %r{Homebrew libraries},
        shell_output("#{HOMEBREW_BREW_FILE} linkage #{full_name}")
    elsif OS.linux?
      Keg.new(prefix).elf_files.each do |file|
        ldd_output = shell_output("ldd #{file}")
        assert_no_match %r{#{Regexp.escape(HOMEBREW_CELLAR)}}, ldd_output
        assert_no_match %r{#{Regexp.escape(HOMEBREW_PREFIX/"opt")}}, ldd_output
      end
    end

    super
  end
end

class PortableFormula < Formula
  def self.inherited(subclass)
    subclass.class_eval do
      keg_only "Portable formula is keg-only."

      # TODO remove `subclass.name !~ /PortableRuby/` when updating portable-ruby to 2.1 or above.
      option "without-universal", "Don't build a universal binary" if OS.mac? && subclass.name !~ /PortableRuby/

      prepend PortableFormulaMixin
    end
  end

  def archs
    # TODO remove below block when updating portable-ruby to 2.1 or above.
    if name == "portable-ruby"
      return [Hardware::CPU.arch_32_bit]
    end

    if build.with? "universal"
      Hardware::CPU.universal_archs
    elsif OS::Mac.prefer_64_bit?
      [Hardware::CPU.arch_64_bit]
    else
      [Hardware::CPU.arch_32_bit]
    end
  end
end
