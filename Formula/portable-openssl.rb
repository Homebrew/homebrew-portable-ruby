require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableOpenssl < PortableFormula
  desc "Portable OpenSSL"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.0.2g.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl-1.0.2g.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.0.2g.tar.gz"
  sha256 "b784b1b3907ce39abf4098702dade6365522a253ad1552e267a9a0e89594aa33"

  depends_on "makedepend" => :build

  # Replace with upstream url if they merge the more robust fix
  # https://github.com/openssl/openssl/pull/597
  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/3f1dc8ea145a70543aded8101a0c725abf82fc45/openssl/revert-pass-pure-constants-verbatim.patch"
    sha256 "e38f84181a56e70028ade8408ad70aaffaea386b7e1b35de55728ae878d544aa"
  end

  patch do
    url "https://raw.githubusercontent.com/Homebrew/patches/3f1dc8ea145a70543aded8101a0c725abf82fc45/openssl/tshort-asm.patch"
    sha256 "f161e2fc1395efcb53d785004d67d4962d28aa8ce282a91020f12809c03b2afd"
  end

  resource "cacert" do
    # homepage "http://curl.haxx.se/docs/caextract.html", "https://github.com/bagder/ca-bundle"
    url "https://raw.githubusercontent.com/bagder/ca-bundle/bff056d04b9e2c92ea8c83b2e39be9c8d0501039/ca-bundle.crt"
    sha256 "0f119da204025da7808273fab42ed8e030cafb5c7ea4e1deda4e75f066f528fb"
  end

  def openssldir
    libexec/"etc/openssl"
  end

  def arch_args
    if OS.mac?
      {
        :x86_64 => %w[darwin64-x86_64-cc enable-ec_nistp_64_gcc_128],
        :i386   => %w[darwin-i386-cc],
      }
    else
      {
        :x86_64 => %w[linux-x86_64],
        :i386  => %w[linux-generic32],
      }
    end
  end

  def configure_args
    %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl2
      zlib-dynamic
      no-shared
      enable-cms
    ]
  end

  def install
    # Load zlib from an explicit path instead of relying on dyld's fallback
    # path, which is empty in a SIP context. This patch will be unnecessary
    # when we begin building openssl with no-comp to disable TLS compression.
    # https://langui.sh/2015/11/27/sip-and-dlopen
    inreplace "crypto/comp/c_zlib.c",
              'zlib_dso = DSO_load(NULL, "z", NULL, 0);',
              'zlib_dso = DSO_load(NULL, "/usr/lib/libz.dylib", NULL, DSO_FLAG_NO_NAME_TRANSLATION);' if OS.mac?

    ENV.permit_arch_flags if build.with? "universal"

    dirs = []

    archs.each do |arch|
      if build.with? "universal"
        dir = "build-#{arch}"
        dirs << dir
        mkdir dir
        mkdir "#{dir}/engines"
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

    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"

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

    openssldir.install resource("cacert").files("ca-bundle.crt" => "cert.pem")
  end
end
