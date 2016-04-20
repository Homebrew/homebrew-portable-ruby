require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableCurl < PortableFormula
  desc "Portable curl"
  homepage "https://curl.haxx.se/"
  url "https://curl.haxx.se/download/curl-7.48.0.tar.bz2"
  sha256 "864e7819210b586d42c674a1fdd577ce75a78b3dda64c63565abe5aefd72c753"

  depends_on "portable-openssl" => :build
  depends_on "pkg-config" => :build

  # Ref: https://curl.haxx.se/mail/archive-2003-03/0115.html
  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["portable-openssl"].opt_prefix}/lib/pkgconfig"
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-shared
      --enable-static
      --prefix=#{prefix}
      --with-ssl=#{Formula["portable-openssl"].opt_prefix}
      --with-ca-bundle=#{Formula["portable-openssl"].opt_prefix/"libexec/openssl/cert.pem"}
      --disable-ldap
      --disable-ares
    ]

    system "./configure", *args
    rm_rf "src/curl"
    system "make", "LDFLAGS=-all-static"
    system "make", "install"
    rm_rf man
  end
end
