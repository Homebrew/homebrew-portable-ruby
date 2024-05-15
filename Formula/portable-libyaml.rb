require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableLibyaml < PortableFormula
  desc "YAML Parser"
  homepage "https://github.com/yaml/libyaml"
  url "https://github.com/yaml/libyaml/archive/refs/tags/0.2.5.tar.gz"
  sha256 "fa240dbf262be053f3898006d502d514936c818e422afdcf33921c63bed9bf2e"
  license "MIT"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "./bootstrap"
    system "./configure", *portable_configure_args,
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <yaml.h>

      int main()
      {
        yaml_parser_t parser;
        yaml_parser_initialize(&parser);
        yaml_parser_delete(&parser);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lyaml", "-o", "test"
    system "./test"
  end
end
