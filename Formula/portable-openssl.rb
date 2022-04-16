require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableOpenssl < PortableFormula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.1.1n.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.1.1n.tar.gz"
  mirror "https://www.openssl.org/source/old/1.1.1/openssl-1.1.1n.tar.gz"
  sha256 "40dceb51a4f6a5275bde0e6bf20ef4b91bfc32ed57c0552e2e8e15463372b17a"
  license "OpenSSL"

  resource "cacert" do
    # https://curl.se/docs/caextract.html
    url "https://curl.se/ca/cacert-2022-03-29.pem"
    sha256 "1979e7fe618c51ed1c9df43bba92f977a0d3fe7497ffa2a5e80dfc559a1e5a29"
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
      no-shared
    ]
  end

  def install
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
