require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableOpenssl < PortableFormula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.1.1l.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.1.1l.tar.gz"
  mirror "https://www.openssl.org/source/old/1.1.1/openssl-1.1.1l.tar.gz"
  sha256 "0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1"
  license "OpenSSL"

  resource "cacert" do
    # https://curl.se/docs/caextract.html
    url "https://curl.se/ca/cacert-2021-09-30.pem"
    sha256 "f524fc21859b776e18df01a87880efa198112214e13494275dbcbd9bcb71d976"
  end

  # Fix build on older macOS versions.
  # Remove with the next version.
  patch do
    url "https://github.com/openssl/openssl/commit/96ac8f13f4d0ee96baf5724d9f96c44c34b8606c.patch?full_index=1"
    sha256 "dd5498c0910c0ae91738fe8e796f4deb4767b08217c1a859fe390147f24809c6"
  end

  # Fix build on older macOS versions.
  # Remove with the next version.
  patch do
    url "https://github.com/openssl/openssl/commit/2f3b120401533db82e99ed28de5fc8aab1b76b33.patch?full_index=1"
    sha256 "a66dcd4a3a291858deefaf260ffd8f2f55da953724e7a14db9c4523d8b7ef383"
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
