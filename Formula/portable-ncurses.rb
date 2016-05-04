require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableNcurses < PortableFormula
  desc "Portable ncurses"
  homepage "https://www.gnu.org/s/ncurses/"
  url "http://ftpmirror.gnu.org/ncurses/ncurses-6.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz"
  sha256 "f551c24b30ce8bfb6e96d9f59b42fbea30fa3a6123384172f9e7284bcf647260"

  depends_on "pkg-config" => :build

  def install
    ENV.universal_binary if build.with? "universal"

    # Fix the build for GCC 5.1
    # error: expected ')' before 'int' in definition of macro 'mouse_trafo'
    # See http://lists.gnu.org/archive/html/bug-ncurses/2014-07/msg00022.html
    # and http://trac.sagemath.org/ticket/18301
    # Disable linemarker output of cpp
    ENV.append "CPPFLAGS", "-P"

    (lib/"pkgconfig").mkpath
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared",
                          "--enable-pc-files",
                          "--with-pkg-config-libdir=#{lib}/pkgconfig",
                          "--enable-sigwinch",
                          "--enable-symlinks",
                          "--enable-widec",
                          "--with-gpm=no"
    system "make", "install"
  end
end
