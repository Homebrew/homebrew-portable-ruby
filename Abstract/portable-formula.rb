# frozen_string_literal: true

module PortableFormulaMixin
  def install
    if OS.mac?
      oldest_macos = if Hardware::CPU.arm?
        :big_sur
      else
        :el_capitan
      end
      if OS::Mac.version > oldest_macos
        opoo <<~EOS
          You are building portable formula on #{OS::Mac.version}.
          As result, formula won't be able to work on older macOS versions.
          It's recommended to build this formula on macOS #{oldest_macos.to_s.humanize.titleize}
          (the oldest version that can run Homebrew).
        EOS
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
      ENV.delete "TERMINFO_DIRS"
      ENV.delete "HOMEBREW_RPATH_PATHS"
      ENV.delete "HOMEBREW_DYNAMIC_LINKER"

      # https://github.com/Homebrew/homebrew-portable-ruby/issues/118
      ENV.append_to_cflags "-fPIC"
    end

    super
  end

  def test
    refute_match(/Homebrew libraries/,
                 shell_output("#{HOMEBREW_BREW_FILE} linkage #{full_name}"))

    super
  end
end

class PortableFormula < Formula
  desc "Abstract portable formula"
  homepage "https://github.com/Homebrew/homebrew-portable-ruby"

  def self.inherited(subclass)
    subclass.class_eval do
      super

      keg_only "portable formulae are keg-only"

      prepend PortableFormulaMixin
    end
  end
end
