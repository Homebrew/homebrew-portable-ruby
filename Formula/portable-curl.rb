require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableCurl < PortableFormula
  desc "Portable curl"
  homepage "https://curl.haxx.se/"
  url "https://curl.haxx.se/download/curl-7.48.0.tar.bz2"
  mirror "http://www.execve.net/curl/curl-7.48.0.tar.bz2"
  sha256 "864e7819210b586d42c674a1fdd577ce75a78b3dda64c63565abe5aefd72c753"

  depends_on "portable-openssl" => :build
  depends_on "pkg-config" => :build

  # Ref: https://curl.haxx.se/mail/archive-2003-03/0115.html
  #      https://curl.haxx.se/mail/lib-2011-12/0093.html
  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["portable-openssl"].opt_prefix}/lib/pkgconfig"
    ENV["LIBS"] = "-Wl,-search_paths_first -ldl" if OS.linux?
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

    ENV.permit_arch_flags if build.with? "universal"
    dirs = []

    archs.each do |arch|
      if build.with? "universal"
        ENV["CFLAGS"] = "-arch #{arch}"
        dir = "build-#{arch}"
        dirs << dir
        mkdir dir
      end

      system "./configure", *args
      system "make", "clean"
      system "make", "LDFLAGS=-all-static -Wl,-search_paths_first"
      system "make", "install"

      if build.with? "universal"
        cp "#{include}/curl/curlbuild.h", dir
        cp Dir["#{lib}/*.a", "#{bin}/*"], dir
      end
    end

    rm_rf man
    rm_rf share/"zsh"

    if build.with? "universal"
      system "lipo", "-create", "#{dirs.first}/libcurl.a",
                                "#{dirs.last}/libcurl.a",
                     "-output", "#{lib}/libcurl.a"

      system "lipo", "-create", "#{dirs.first}/curl",
                                "#{dirs.last}/curl",
                     "-output", "#{bin}/curl"

      confs = archs.map do |arch|
        <<-EOS.undent
          #ifdef __#{arch}__
          #{(buildpath/"build-#{arch}/curlbuild.h").read}
          #endif
          EOS
      end
      (include/"curl/curlbuild.h").atomic_write confs.join("\n")
    end

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
