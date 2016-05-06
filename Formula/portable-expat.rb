require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableExpat < PortableFormula
  desc "Portable expat"
  homepage "http://www.libexpat.org"
  url "https://downloads.sourceforge.net/project/expat/expat/2.1.0/expat-2.1.0.tar.gz"
  mirror "https://fossies.org/linux/www/expat-2.1.0.tar.gz"
  sha256 "823705472f816df21c8f6aa026dd162b280806838bb55b3432b0fb1fcca7eb86"

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end
end
