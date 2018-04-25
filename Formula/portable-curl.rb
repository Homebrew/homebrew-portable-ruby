require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableCurl < PortableFormula
  desc "Portable curl"
  homepage "https://curl.haxx.se/"
  url "https://curl.haxx.se/download/curl-7.58.0.tar.bz2"
  mirror "http://curl.askapache.com/download/curl-7.58.0.tar.bz2"
  sha256 "1cb081f97807c01e3ed747b6e1c9fee7a01cb10048f1cd0b5f56cfe0209de731"

  depends_on "pkg-config" => :build
  depends_on "portable-openssl" => :build

  resource "curl-ca-bundle" do
    url "https://curl.haxx.se/ca/cacert-2018-01-17.pem"
    sha256 "defe310a0184a12e4b1b3d147f1d77395dd7a09e3428373d019bef5d542ceba3"
  end

  def install
    resource("curl-ca-bundle").stage do
      share.install "cacert-2018-01-17.pem" => "cacert.pem"
    end

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --bindir=#{libexec}
      --enable-static
      --disable-shared
    ]

    args << "--with-ssl=#{Formula["portable-openssl"].opt_prefix}"
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["portable-openssl"].opt_lib}/pkgconfig"

    system "./configure", *args
    system "make", "install"
    (bin/"curl").write <<~EOS
    #!/bin/sh

    SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
    exec "${SCRIPTPATH}/../libexec/curl" --cacert "${SCRIPTPATH}/../share/cacert.pem" "$@"
    EOS
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = (testpath/"test.tar.gz")
    system "#{bin}/curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum
  end
end
