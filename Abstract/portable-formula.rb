# frozen_string_literal: true

module PortableFormulaMixin
  if OS.mac?
    if Hardware::CPU.arm?
      TARGET_MACOS = :big_sur
      TARGET_DARWIN_VERSION = Version.new("20.1.0").freeze
    else
      TARGET_MACOS = :el_capitan
      TARGET_DARWIN_VERSION = Version.new("15.0.0").freeze
    end

    CROSS_COMPILING = OS.kernel_version.major != TARGET_DARWIN_VERSION.major
  end

  def portable_configure_args
    # Allow cross-compile between Darwin versions (used by our fake El Capitan on High Sierra setup)
    if OS.mac? && CROSS_COMPILING
      cpu = if Hardware::CPU.arm?
        "aarch64"
      else
        "x86_64"
      end
      %W[
        --build=#{cpu}-apple-darwin#{OS.kernel_version}
        --host=#{cpu}-apple-darwin#{TARGET_DARWIN_VERSION}
      ]
    else
      []
    end
  end

  def install
    if OS.mac?
      if OS::Mac.version > TARGET_MACOS
        opoo <<~EOS
          You are building portable formula on #{OS::Mac.version}.
          As result, formula won't be able to work on older macOS versions.
          It's recommended to build this formula on macOS #{TARGET_MACOS.to_s.humanize.titleize}
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
