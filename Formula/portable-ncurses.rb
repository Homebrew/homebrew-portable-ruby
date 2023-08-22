require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableNcurses < PortableFormula
  desc "Text-based UI library"
  homepage "https://invisible-island.net/ncurses/announce.html"
  url "https://ftp.gnu.org/gnu/ncurses/ncurses-6.4.tar.gz"
  mirror "https://invisible-mirror.net/archives/ncurses/ncurses-6.4.tar.gz"
  mirror "https://ftpmirror.gnu.org/ncurses/ncurses-6.4.tar.gz"
  sha256 "6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159"
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
                          "--without-ada",
                          "--without-cxx-binding",
                          "--without-manpages",
                          "--without-progs",
                          "--without-tests",
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
