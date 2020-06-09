require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableNcurses < PortableFormula
  desc "Text-based UI library"
  homepage "https://www.gnu.org/s/ncurses/"
  url "https://ftp.gnu.org/gnu/ncurses/ncurses-6.2.tar.gz"
  mirror "https://ftpmirror.gnu.org/ncurses/ncurses-6.2.tar.gz"
  sha256 "30306e0c76e0f9f1f0de987cf1c82a5c21e1ce6568b9227f7da5b71cbea86c9d"

  depends_on "pkg-config" => :build

  def install
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
      lib.install_symlink "lib#{name}w.a" => "lib#{name}.a"
      lib.install_symlink "lib#{name}w_g.a" => "lib#{name}_g.a"
    end

    lib.install_symlink "libncurses++w.a" => "libncurses++.a"
    lib.install_symlink "libncurses.a" => "libcurses.a"

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

    (testpath/"test.c").write <<~EOS
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
