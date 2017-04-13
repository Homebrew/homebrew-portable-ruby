require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableCurl < PortableFormula
  desc "Portable curl"
  homepage "https://curl.haxx.se/"
  url "https://curl.haxx.se/download/curl-7.53.1.tar.bz2"
  sha256 "1c7207c06d75e9136a944a2e0528337ce76f15b9ec9ae4bb30d703b59bf530e8"

  depends_on "portable-openssl" => :build
  depends_on "pkg-config" => :build
  if OS.linux?
    depends_on "portable-zlib" => :build
    depends_on "portable-c-ares" => :build
  end

  # Ref: https://curl.haxx.se/mail/archive-2003-03/0115.html
  #      https://curl.haxx.se/mail/lib-2011-12/0093.html
  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["portable-openssl"].opt_lib}/pkgconfig"
    ENV["LIBS"] = `pkg-config openssl --static --libs`.chomp

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-shared
      --enable-static
      --prefix=#{prefix}
      --with-ssl=#{Formula["portable-openssl"].opt_prefix}
      --disable-ldap
      --without-librtmp
      --without-libidn
    ]

    if OS.mac?
      args << "--disable-ares"
    else
      cares = Formula["portable-c-ares"]
      args << "--enable-ares=#{cares.opt_prefix}"
      ENV.append "LIBS", "-L#{cares.opt_prefix}/lib -lcares"
    end

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
      ENV.append "LDFLAGS", "-all-static"
      system "make"
      ENV.remove "LDFLAGS", "-all-static"
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
    cp Formula["portable-openssl"].opt_libexec/"etc/openssl/cert.pem", libexec/"cert.pem"
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    ENV["PATH"] = "/usr/bin:/bin"
    system testpath/"bin/curl", "-V"
    system testpath/"bin/curl", "-v", "-I", "https://www.google.com"
  end
end
