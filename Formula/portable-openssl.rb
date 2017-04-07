require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableOpenssl < PortableFormula
  desc "Portable OpenSSL"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.0.2h.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl-1.0.2h.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.0.2h.tar.gz"
  sha256 "1d4007e53aad94a5b2002fe045ee7bb0b3d98f1a47f8b2bc851dcd1c74332919"

  depends_on "makedepend" => :build

  resource "cacert" do
    # http://curl.haxx.se/docs/caextract.html
    url "https://curl.haxx.se/ca/cacert-2017-01-18.pem"
    sha256 "e62a07e61e5870effa81b430e1900778943c228bd7da1259dd6a955ee2262b47"
  end

  # Fixes ASM for i386 builds on older OS Xs
  patch :p0 do
    url "https://trac.macports.org/export/144472/trunk/dports/devel/openssl/files/x86_64-asm-on-i386.patch"
    sha256 "98ffb308aa04c14db9c21769f1c5ff09d63eb85ce9afdf002598823c45edef6d"
  end

  def openssldir
    libexec/"etc/openssl"
  end

  def arch_args
    if OS.mac?
      {
        :x86_64 => %w[darwin64-x86_64-cc enable-ec_nistp_64_gcc_128],
        :i386   => %w[darwin-i386-cc],
        :ppc    => %w[darwin-ppc-cc],
        :ppc64  => %w[darwin64-ppc-cc]
      }
    else
      {
        :x86_64 => %w[linux-x86_64],
        :i386  => %w[linux-generic32],
      }
    end
  end

  def configure_args
    args = %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl2
      zlib-dynamic
      no-shared
      enable-cms
    ]

    args << "no-asm" if OS.mac? && MacOS.version < :leopard

    args
  end

  def install
    # Load zlib from an explicit path instead of relying on dyld's fallback
    # path, which is empty in a SIP context. This patch will be unnecessary
    # when we begin building openssl with no-comp to disable TLS compression.
    # https://langui.sh/2015/11/27/sip-and-dlopen
    inreplace "crypto/comp/c_zlib.c",
              'zlib_dso = DSO_load(NULL, "z", NULL, 0);',
              'zlib_dso = DSO_load(NULL, "/usr/lib/libz.dylib", NULL, DSO_FLAG_NO_NAME_TRANSLATION);' if OS.mac?

    dirs = []

    archs.each do |arch|
      if build.with? "universal"
        dir = "build-#{arch}"
        dirs << dir
        mkdir dir
        system "make", "clean"
      end

      ENV.deparallelize
      system "perl", "./Configure", *(configure_args + arch_args[arch])
      system "make", "depend"
      system "make"
      system "make", "test"

      if build.with? "universal"
        cp "include/openssl/opensslconf.h", dir
        cp Dir["*.a", "apps/openssl"], dir
      end
    end

    system "make", "install", "MANDIR=#{man}"
    rm_rf man

    if build.with? "universal"
      %w[libcrypto libssl].each do |libname|
        system "lipo", "-create", "#{dirs.first}/#{libname}.a",
                                  "#{dirs.last}/#{libname}.a",
                       "-output", "#{lib}/#{libname}.a"
      end

      system "lipo", "-create", "#{dirs.first}/openssl",
                                "#{dirs.last}/openssl",
                     "-output", "#{bin}/openssl"

      confs = archs.map do |arch|
        <<-EOS.undent
          #ifdef __#{arch}__
          #{(buildpath/"build-#{arch}/opensslconf.h").read}
          #endif
          EOS
      end
      (include/"openssl/opensslconf.h").atomic_write confs.join("\n")
    end

    cacert = resource("cacert")
    filename = Pathname.new(cacert.url).basename
    openssldir.install cacert.files(filename => "cert.pem")
  end
  end
end
