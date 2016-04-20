require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableReadline < PortableFormula
  desc "Portable readline"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "http://ftpmirror.gnu.org/readline/readline-6.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz"
  version "6.3.8"
  sha256 "56ba6071b9462f980c5a72ab0023893b65ba6debb4eeb475d7a563dc65cafd43"

  patch do
    url "https://gist.githubusercontent.com/jacknagel/d886531fb6623b60b2af/raw/746fc543e56bc37a26ccf05d2946a45176b0894e/readline-6.3.8.diff"
    sha256 "ef4fd6f24103b8f1d1199a6254d81a0cd63329bd2449ea9b93e66caf76d7ab89"
  end

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--prefix=#{prefix}",
                          "--enable-multibyte",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end
end
