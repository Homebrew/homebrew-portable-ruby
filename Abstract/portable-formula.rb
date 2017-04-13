module PortableFormulaMixin
  def install
    if OS.mac?
      tag = Hardware::CPU.ppc? ? :tiger : :leopard
      if OS::Mac.version > tag
        opoo <<-EOS.undent
          You are building portable formula on #{OS::Mac.version}.
          As result, formula won't be able to work for macOS at lower version.
          It's recommended to build this formula on OS X #{tag.capitalize}.
        EOS
      end

      # Overrideable per-formula, but try to make sure our universal
      # arches make it into the environment.
      # This is important because in some environments (e.g. 10.4/10.5)
      # our arches differ from the usual defaults.
      if build.with?("universal")
        ENV.permit_arch_flags
        ENV.append_to_cflags archs.map {|a| "-arch #{a}"}.join(" ")
      end

      # Always prefer to linking to portable libs.
      ENV.append "LDFLAGS", "-Wl,-search_paths_first"
    elsif OS.linux?
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
    assert_no_match %r{Homebrew libraries},
      shell_output("#{HOMEBREW_BREW_FILE} linkage #{full_name}")

    super
  end
end

class PortableFormula < Formula
  def self.inherited(subclass)
    subclass.class_eval do
      keg_only "Portable formula is keg-only."

      # TODO remove `subclass.name !~ /PortableRuby$/` when updating portable-ruby to 2.1 or above.
      option "without-universal", "Don't build a universal binary" if OS.mac? && subclass.name !~ /PortableRuby$/

      prepend PortableFormulaMixin
    end
  end

  def archs
    # TODO remove below block when updating portable-ruby to 2.1 or above.
    if name == "portable-ruby"
      return [Hardware::CPU.arch_32_bit]
    end

    # On Tiger and Leopard, override the default behaviour.
    # Normally we don't build 64-bit there, because the linker is
    # temperamental, and so "universal" builds don't usually happen.
    # However, for the purposes of distributing portable packages,
    # it's very useful to be able to build i386/ppc binaries for use
    # on both Intel and PowerPC Macs. The Apple-provided compilers
    # are capable of this on both Intel and PowerPC hosts.
    if OS.mac? && OS::Mac.version < :snow_leopard
      if build.with? "universal"
        return [:i386, :ppc]
      else
        return [Hardware::CPU.arch_32_bit]
      end
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
