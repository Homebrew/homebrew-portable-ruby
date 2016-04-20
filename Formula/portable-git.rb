require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableGit < PortableFormula
  desc "Portable git"
  homepage "https://git-scm.com"
  url "https://www.kernel.org/pub/software/scm/git/git-2.8.1.tar.xz"
  sha256 "e6626b43ba4bc63ad4918df4c275f50bd7f8af2ab54bde60496ad75e91e927fc"

  depends_on "portable-curl" => :build

  def install
    # If these things are installed, tell Git build system to not use them
    ENV["NO_FINK"] = "1"
    ENV["NO_DARWIN_PORTS"] = "1"
    ENV["V"] = "1" # build verbosely
    ENV["NO_R_TO_GCC_LINKER"] = "1" # pass arguments to LD correctly
    ENV["PYTHON_PATH"] = which "python"
    ENV["PERL_PATH"] = which "perl"
    ENV["NO_PERL_MAKEMAKER"] = "1"
    ENV["NO_GETTEXT"] = "1"
    ENV["NO_TCLTK"] = "1"
    ENV["NO_OPENSSL"] = "1"
    args = %W[
      prefix=#{prefix}
      CC=#{ENV.cc}
      CFLAGS=#{ENV.cflags}
      LDFLAGS=#{ENV.ldflags}
    ]
    system "make", "install", *args
  end
end
