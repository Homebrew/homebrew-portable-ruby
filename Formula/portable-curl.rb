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
      --disable-ldap
      --disable-ares
    ]

    system "./configure", *args
    rm_rf "src/curl"
    system "make", "LDFLAGS=-all-static"
    system "make", "install"
    rm_rf man

    (libexec/"bin").mkpath
    bin.children.each do |file|
      (libexec/"bin").install file
      file.write <<-EOS.undent
        #!/bin/bash
        CURL_LIBEXEC="$(cd "${0%/*}/.." && pwd -P)/libexec"
        CURL_CA_BUNDLE="$CURL_LIBEXEC/cert.pem" exec "$CURL_LIBEXEC/bin/#{file.basename}" "$@"
      EOS
    end
    cp Formula["portable-openssl"].opt_prefix/"libexec/etc/openssl/cert.pem", libexec/"cert.pem"
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    ENV["PATH"] = "/usr/bin:/bin"
    system testpath/"bin/curl", "-V"
    system testpath/"bin/curl", "-v", "-I", "https://www.google.com"
  end
end
