require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableLibedit < PortableFormula
  desc "BSD-style licensed readline alternative"
  homepage "https://thrysoee.dk/editline/"
  url "https://thrysoee.dk/editline/libedit-20230828-3.1.tar.gz"
  version "20230828-3.1"
  sha256 "4ee8182b6e569290e7d1f44f0f78dac8716b35f656b76528f699c69c98814dad"
  license "BSD-3-Clause"

  on_linux do
    depends_on "portable-ncurses" => :build
  end

  def install
    system "./configure", *portable_configure_args,
                          *std_configure_args,
                          "--enable-static",
                          "--disable-shared",
                          "--disable-examples"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <histedit.h>
      int main(int argc, char *argv[]) {
        EditLine *el = el_init(argv[0], stdin, stdout, stderr);
        return (el == NULL);
      }
    EOS
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-ledit", "-I#{include}"
    system "./test"
  end
end
