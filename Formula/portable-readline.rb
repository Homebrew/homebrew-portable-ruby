require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableReadline < PortableFormula
  desc "Portable readline"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "https://ftpmirror.gnu.org/readline/readline-7.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz"
  version "7.0.3"
  sha256 "750d437185286f40a369e1e4f4764eda932b9459b5ec9a731628393dd3d32334"

  %w[
    001 9ac1b3ac2ec7b1bf0709af047f2d7d2a34ccde353684e57c6b47ebca77d7a376
    002 8747c92c35d5db32eae99af66f17b384abaca961653e185677f9c9a571ed2d58
    003 9e43aa93378c7e9f7001d8174b1beb948deefa6799b6f581673f465b7d9d4780
  ].each_slice(2) do |p, checksum|
    patch :p0 do
      url "https://ftpmirror.gnu.org/readline/readline-7.0-patches/readline70-#{p}"
      mirror "https://ftp.gnu.org/gnu/readline/readline-7.0-patches/readline70-#{p}"
      sha256 checksum
    end
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

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <stdlib.h>
      #include <readline/readline.h>

      int main()
      {
        printf("%s\\n", readline("test> "));
        return 0;
      }
    EOS
    args = %W[test.c -I#{include} -L#{lib} -lreadline -lncurses -o test]
    if OS.linux?
      ncurses = Formula["portable-ncurses"]
      args += %W[-I#{ncurses.include} -L#{ncurses.lib}]
    end
    system ENV.cc, *args
    assert_equal "test> Hello, World!\nHello, World!",
      pipe_output("./test", "Hello, World!\n").strip
  end
end
