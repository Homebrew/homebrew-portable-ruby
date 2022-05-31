require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableReadline < PortableFormula
  desc "Library for command-line editing"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "https://ftp.gnu.org/gnu/readline/readline-8.1.tar.gz"
  mirror "https://ftpmirror.gnu.org/readline/readline-8.1.tar.gz"
  version "8.1.2"
  sha256 "f8ceb4ee131e3232226a17f51b164afc46cd0b9e6cef344be87c65962cb82b02"
  license "GPL-3.0-or-later"

  %w[
    001 682a465a68633650565c43d59f0b8cdf149c13a874682d3c20cb4af6709b9144
    002 e55be055a68cb0719b0ccb5edc9a74edcc1d1f689e8a501525b3bc5ebad325dc
  ].each_slice(2) do |p, checksum|
    patch :p0 do
      url "https://ftp.gnu.org/gnu/readline/readline-8.1-patches/readline81-#{p}"
      mirror "https://ftpmirror.gnu.org/readline/readline-8.1-patches/readline81-#{p}"
      sha256 checksum
    end
  end

  depends_on "portable-ncurses" => :build if OS.linux?

  def install
    args = portable_configure_args + %W[
      --prefix=#{prefix}
      --enable-static
      --disable-shared
    ]
    args << "--with-curses" if OS.linux?
    system "./configure", *args
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
