require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableOpenssl < PortableFormula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-3.1.0.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-3.1.0.tar.gz"
  mirror "https://www.openssl.org/source/old/3.1/openssl-3.1.0.tar.gz"
  sha256 "aaa925ad9828745c4cad9d9efeb273deca820f2cdcf2c3ac7d7c1212b7c497b4"
  license "OpenSSL"

  resource "cacert" do
    # https://curl.se/docs/caextract.html
    url "https://curl.se/ca/cacert-2023-01-10.pem"
    sha256 "fb1ecd641d0a02c01bc9036d513cb658bbda62a75e246bedbc01764560a639f0"
  end

  # fix build on macOS pre-10.14; remove in 3.1.1; see openssl/openssl#19361
  patch do
    url "https://github.com/openssl/openssl/commit/96f1dbea67247b79b1e7b3f83f2964dc626d86ce.patch?full_index=1"
    sha256 "95d662ce38c84bb7e4ca1f78420815360f6254e95854915b067739db23e4df20"
  end
  patch do
    url "https://github.com/openssl/openssl/commit/d4765408c705f704f7cf33bd32bfb713061954a7.patch?full_index=1"
    sha256 "fe79b4bfe1daf2995b49b3a57bc1d4f07d615871300424ce9091096e3bb1501b"
  end
  patch do
    url "https://github.com/openssl/openssl/commit/110dac578358014c29b86cf18d9a4bfe5561e3bc.patch?full_index=1"
    sha256 "27da17844cb47fbeaac237ad8082d2e2c8ace523fd93b07a5a7fde6d6ad05c62"
  end

  def openssldir
    libexec/"etc/openssl"
  end

  def arch_args
    if OS.mac?
      %W[darwin64-#{Hardware::CPU.arch}-cc enable-ec_nistp_64_gcc_128]
    elsif Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        ["linux-x86_64"]
      else
        ["linux-elf"]
      end
    elsif Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        ["linux-aarch64"]
      else
        ["linux-armv4"]
      end
    end
  end

  def configure_args
    %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      --libdir=#{lib}
      no-shared
    ]
  end

  def install
    # OpenSSL is not fully portable and certificate paths are backed into the library.
    # We therefore need to set the certificate path at runtime via an environment variable.
    # We however don't want to touch _other_ OpenSSL usages, so we change the variable name to differ.
    inreplace "include/internal/cryptlib.h", "\"SSL_CERT_FILE\"", "\"PORTABLE_RUBY_SSL_CERT_FILE\""

    openssldir.mkpath
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make"
    system "make", "test"

    system "make", "install_sw"

    # Ruby doesn't support passing --static to pkg-config.
    # Unfortunately, this means we need to modify the OpenSSL pc file.
    # This is a Ruby bug - not an OpenSSL one.
    inreplace lib/"pkgconfig/libcrypto.pc", "\nLibs.private:", ""

    cacert = resource("cacert")
    filename = Pathname.new(cacert.url).basename
    openssldir.install cacert.files(filename => "cert.pem")
  end

  test do
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system bin/"openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
