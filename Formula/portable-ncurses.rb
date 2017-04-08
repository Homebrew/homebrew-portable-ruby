require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableNcurses < PortableFormula
  desc "Portable ncurses"
  homepage "https://www.gnu.org/s/ncurses/"
  url "https://ftpmirror.gnu.org/ncurses/ncurses-6.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz"
  sha256 "f551c24b30ce8bfb6e96d9f59b42fbea30fa3a6123384172f9e7284bcf647260"
  revision 1

  depends_on "pkg-config" => :build

  # stable rollup patch created by upstream see
  # http://invisible-mirror.net/archives/ncurses/6.0/README
  resource "ncurses-6.0-20160910-patch.sh" do
    url "http://invisible-mirror.net/archives/ncurses/6.0/ncurses-6.0-20160910-patch.sh.bz2"
    mirror "https://www.mirrorservice.org/sites/lynx.invisible-island.net/ncurses/6.0/ncurses-6.0-20160910-patch.sh.bz2"
    sha256 "f570bcfe3852567f877ee6f16a616ffc7faa56d21549ad37f6649022f8662538"
  end

  def install
    ENV.universal_binary if build.with? "universal"

    # Fix the build for GCC 5.1
    # error: expected ')' before 'int' in definition of macro 'mouse_trafo'
    # See http://lists.gnu.org/archive/html/bug-ncurses/2014-07/msg00022.html
    # and http://trac.sagemath.org/ticket/18301
    # Disable linemarker output of cpp
    ENV.append "CPPFLAGS", "-P"

    (lib/"pkgconfig").mkpath

    # stage and apply patch
    buildpath.install resource("ncurses-6.0-20160910-patch.sh")
    system "sh", "ncurses-6.0-20160910-patch.sh"

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

    %w[form menu ncurses panel].each do |name|
      lib.install_symlink "lib#{name}w.#{major}.dylib" => "lib#{name}.dylib"
      lib.install_symlink "lib#{name}w.#{major}.dylib" => "lib#{name}.#{major}.dylib"
      lib.install_symlink "lib#{name}w.a" => "lib#{name}.a"
      lib.install_symlink "lib#{name}w_g.a" => "lib#{name}_g.a"
    end

    lib.install_symlink "libncurses++w.a" => "libncurses++.a"
    lib.install_symlink "libncurses.a" => "libcurses.a"
    lib.install_symlink "libncurses.dylib" => "libcurses.dylib"

    (lib/"pkgconfig").install_symlink "ncursesw.pc" => "ncurses.pc"

    bin.install_symlink "ncursesw#{major}-config" => "ncurses#{major}-config"

    include.install_symlink [
      "ncursesw/curses.h", "ncursesw/form.h", "ncursesw/ncurses.h",
      "ncursesw/panel.h", "ncursesw/term.h", "ncursesw/termcap.h"
    ]
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    system testpath/"bin/tput", "cols"

    (testpath/"test.c").write <<-EOS.undent
      #include <ncursesw/curses.h>
      int main()
      {
        tgetnum("");
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lncurses", "-o", "test"
    system "./test"
  end
end
