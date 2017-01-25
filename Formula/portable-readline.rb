require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableReadline < PortableFormula
  desc "Portable readline"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "http://ftpmirror.gnu.org/readline/readline-6.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz"
  version "6.3.8"
  sha256 "56ba6071b9462f980c5a72ab0023893b65ba6debb4eeb475d7a563dc65cafd43"

  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-001"
    sha256 "1a79bbb6eaee750e0d6f7f3d059b30a45fc54e8e388a8e05e9c3ae598590146f"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-002"
    sha256 "39e304c7a526888f9e112e733848215736fb7b9d540729b9e31f3347b7a1e0a5"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-003"
    sha256 "ec41bdd8b00fd884e847708513df41d51b1243cecb680189e31b7173d01ca52f"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-004"
    sha256 "4547b906fb2570866c21887807de5dee19838a60a1afb66385b272155e4355cc"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-005"
    sha256 "877788f9228d1a9907a4bcfe3d6dd0439c08d728949458b41208d9bf9060274b"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-006"
    sha256 "5c237ab3c6c97c23cf52b2a118adc265b7fb411b57c93a5f7c221d50fafbe556"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-007"
    sha256 "4d79b5a2adec3c2e8114cbd3d63c1771f7c6cf64035368624903d257014f5bea"
  end
  patch :p0 do
    url "https://ftp.gnu.org/gnu/readline/readline-6.3-patches/readline63-008"
    sha256 "3bc093cf526ceac23eb80256b0ec87fa1735540d659742107b6284d635c43787"
  end

  depends_on "portable-ncurses" => :build if OS.linux?

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--prefix=#{prefix}",
                          "--enable-multibyte",
                          "--enable-static",
                          "--disable-shared",
                          ("--with-curses" if OS.linux?)
    args = []
    args << "SHLIB_LIBS=-lcurses" if OS.linux?
    system "make", "install", *args
  end
end
