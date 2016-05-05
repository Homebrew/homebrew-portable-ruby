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
    make_libncurses_symlinks
  end

  def make_libncurses_symlinks
    major = version.to_s.split(".")[0]

    cd lib do
      %w[form menu ncurses panel].each do |name|
        ln_s "lib#{name}w.a", "lib#{name}.a"
        ln_s "lib#{name}w_g.a", "lib#{name}_g.a"
      end

      ln_s "libncurses++w.a", "libncurses++.a"
      ln_s "libncurses.a", "libcurses.a"
    end

    cd bin do
      ln_s "ncursesw#{major}-config", "ncurses#{major}-config"
    end

    ln_s [
      "ncursesw/curses.h", "ncursesw/form.h", "ncursesw/ncurses.h",
      "ncursesw/term.h", "ncursesw/termcap.h"], include
  end
end
