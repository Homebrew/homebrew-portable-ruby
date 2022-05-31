require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableNcurses < PortableFormula
  desc "Text-based UI library"
  homepage "https://invisible-island.net/ncurses/announce.html"
  url "https://ftp.gnu.org/gnu/ncurses/ncurses-6.3.tar.gz"
  mirror "https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz"
  mirror "https://ftpmirror.gnu.org/ncurses/ncurses-6.3.tar.gz"
  sha256 "97fc51ac2b085d4cde31ef4d2c3122c21abc217e9090a43a30fc5ec21684e059"
  license "MIT"

  depends_on "pkg-config" => :build

  def install
    # Workaround for
    # macOS: mkdir: /usr/lib/pkgconfig:/opt/homebrew/Library/Homebrew/os/mac/pkgconfig/12: Operation not permitted
    # Linux: configure: error: expected a pathname, not ""
    (lib/"pkgconfig").mkpath

    system "./configure", *portable_configure_args,
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared",
                          "--without-cxx-binding",
                          "--enable-pc-files",
                          "--with-pkg-config-libdir=#{lib}/pkgconfig",
                          "--enable-sigwinch",
                          "--enable-symlinks",
                          "--enable-widec",
                          "--with-gpm=no",
                          "--without-ada"
    system "make", "install"
    make_libncurses_symlinks
  end

  def make_libncurses_symlinks
    major = version.major.to_s

    %w[form menu ncurses panel].each do |name|
      lib.install_symlink "lib#{name}w.a" => "lib#{name}.a"
      lib.install_symlink "lib#{name}w_g.a" => "lib#{name}_g.a"
    end

    lib.install_symlink "libncurses.a" => "libcurses.a"

    (lib/"pkgconfig").install_symlink "ncursesw.pc" => "ncurses.pc"

    bin.install_symlink "ncursesw#{major}-config" => "ncurses#{major}-config"

    include.install_symlink "ncursesw" => "ncurses"
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
