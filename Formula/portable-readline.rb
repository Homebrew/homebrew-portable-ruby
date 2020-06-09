require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableReadline < PortableFormula
  desc "Library for command-line editing"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "https://ftpmirror.gnu.org/readline/readline-8.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz"
  version "8.0.4"
  sha256 "e339f51971478d369f8a053a330a190781acb9864cf4c541060f12078948e461"

  %w[
    001 d8e5e98933cf5756f862243c0601cb69d3667bb33f2c7b751fe4e40b2c3fd069
    002 36b0febff1e560091ae7476026921f31b6d1dd4c918dcb7b741aa2dad1aec8f7
    003 94ddb2210b71eb5389c7756865d60e343666dfb722c85892f8226b26bb3eeaef
    004 b1aa3d2a40eee2dea9708229740742e649c32bb8db13535ea78f8ac15377394c
  ].each_slice(2) do |p, checksum|
    patch :p0 do
      url "https://ftp.gnu.org/gnu/readline/readline-8.0-patches/readline80-#{p}"
      mirror "https://ftpmirror.gnu.org/readline/readline-8.0-patches/readline80-#{p}"
      sha256 checksum
    end
  end

  depends_on "portable-ncurses" => :build if OS.linux?

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--enable-multibyte",
                          "--enable-static",
                          "--disable-shared",
                          ("--with-curses" if OS.linux?)
    system "make", "install"
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
