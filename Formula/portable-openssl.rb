require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableOpenssl < PortableFormula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.1.1g.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl-1.1.1g.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.1.1g.tar.gz"
  sha256 "ddb04774f1e32f0c49751e21b67216ac87852ceb056b75209af2443400636d46"

  resource "cacert" do
    # http://curl.haxx.se/docs/caextract.html
    url "https://curl.haxx.se/ca/cacert-2020-01-01.pem"
    sha256 "adf770dfd574a0d6026bfaa270cb6879b063957177a991d453ff1d302c02081f"
  end

  def openssldir
    libexec/"etc/openssl"
  end

  def arch_args
    if OS.mac?
      ["darwin64-x86_64-cc", "enable-ec_nistp_64_gcc_128"]
    else
      args = ["enable-md2"]
      if Hardware::CPU.intel?
        if Hardware::CPU.is_64_bit?
          args << "linux-x86_64"
        else
          args << "linux-elf"
        end
      elsif Hardware::CPU.arm?
        if Hardware::CPU.is_64_bit?
          args << "linux-aarch64"
        else
          args << "linux-armv4"
        end
      end
      args
    end
  end

  def configure_args
    args = %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-shared
    ]

    args
  end

  def install
    ENV.deparallelize
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make"
    system "make", "test"

    system "make", "install", "MANDIR=#{man}"
    rm_rf man

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
