require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableCAres < PortableFormula
  desc "Asynchronous DNS library"
  homepage "https://c-ares.haxx.se/"
  url "https://c-ares.haxx.se/download/c-ares-1.12.0.tar.gz"
  mirror "https://launchpad.net/ubuntu/+archive/primary/+files/c-ares_1.12.0.orig.tar.gz"
  sha256 "8692f9403cdcdf936130e045c84021665118ee9bfea905d1a76f04d4e6f365fb"

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-debug",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <stdio.h>
      #include <ares.h>

      int main()
      {
        ares_library_init(ARES_LIB_INIT_ALL);
        ares_library_cleanup();
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcares", "-o", "test"
    system "./test"
  end
end
