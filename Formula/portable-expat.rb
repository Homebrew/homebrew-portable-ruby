require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableExpat < PortableFormula
  desc "Portable expat"
  homepage "http://www.libexpat.org"
  url "https://downloads.sourceforge.net/project/expat/expat/2.2.5/expat-2.2.5.tar.bz2"
  mirror "https://fossies.org/linux/www/expat-2.2.5.tar.bz2"
  sha256 "d9dc32efba7e74f788fcc4f212a43216fc37cf5f23f4c2339664d473353aedf6"

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    (testpath/"test.xml").write <<~EOS
      <?xml version="1.0" standalone="yes"?>
      <str>Hello, world!</str>
    EOS
    system testpath/"bin/xmlwf", "test.xml"

    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include "expat.h"

      static void XMLCALL my_StartElementHandler(
        void *userdata,
        const XML_Char *name,
        const XML_Char **atts)
      {
        printf("tag:%s|", name);
      }

      static void XMLCALL my_CharacterDataHandler(
        void *userdata,
        const XML_Char *s,
        int len)
      {
        printf("data:%.*s|", len, s);
      }

      int main()
      {
        static const char str[] = "<str>Hello, world!</str>";
        int result;

        XML_Parser parser = XML_ParserCreate("utf-8");
        XML_SetElementHandler(parser, my_StartElementHandler, NULL);
        XML_SetCharacterDataHandler(parser, my_CharacterDataHandler);
        result = XML_Parse(parser, str, sizeof(str), 1);
        XML_ParserFree(parser);

        return result;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lexpat", "-o", "test"
    assert_equal "tag:str|data:Hello, world!|", shell_output("./test")
  end
end
