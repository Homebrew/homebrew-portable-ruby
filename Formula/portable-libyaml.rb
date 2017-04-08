require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableLibyaml < PortableFormula
  desc "Portable libyaml"
  homepage "http://pyyaml.org/wiki/LibYAML"
  url "http://pyyaml.org/download/libyaml/yaml-0.1.7.tar.gz"
  mirror "https://mirrors.kernel.org/debian/pool/main/liby/libyaml/libyaml_0.1.7.orig.tar.gz"
  sha256 "8088e457264a98ba451a90b8661fcb4f9d6f478f7265d48322a196cec2480729"

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
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
