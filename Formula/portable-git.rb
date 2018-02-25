require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableGit < PortableFormula
  desc "Portable git"
  homepage "https://git-scm.com"
  url "https://www.kernel.org/pub/software/scm/git/git-2.16.2.tar.xz"
  sha256 "5560578bd21468d98637f41515c165d32f69caff0838b8989dee5ce10022c717"

  if OS.mac? && MacOS.version < :leopard
    # system tar has odd permissions errors
    depends_on "gnu-tar" => :build
  end

  depends_on "portable-curl" => :build
  if OS.linux? || OS::Mac.version < :leopard
    depends_on "portable-expat" => :build
  end

  depends_on "portable-openssl" => :build
  depends_on "portable-zlib" => :build if OS.linux?

  # ld64 understands -rpath but rejects it on Tiger
  if OS.mac? && MacOS.version < :leopard
    patch :p1 do
      url "https://trac.macports.org/export/106975/trunk/dports/devel/git-core/files/patch-Makefile.diff"
      sha256 "6d1484c7ed726525b0f01e2da1a22311c371d48965435d67bcee844a9995d956"
    end
  end

  resource "curl-ca-bundle" do
    url "https://curl.haxx.se/ca/cacert-2018-01-17.pem"
    sha256 "defe310a0184a12e4b1b3d147f1d77395dd7a09e3428373d019bef5d542ceba3"
  end

  def install
    resource("curl-ca-bundle").stage do
      libexec.install "cacert-2018-01-17.pem" => "cert.pem"
    end

    if OS.mac? && MacOS.version < :leopard
      tar = Formula["gnu-tar"]
      tab = Tab.for_keg tar.installed_prefix
      tar_name = tab.used_options.include?("--with-default-names") ? tar.bin/"tar" : tar.bin/"gtar"
      inreplace "Makefile" do |s|
        s.change_make_var! "TAR", tar_name.to_s
      end
    end

    curl = Formula["portable-curl"]
    expat = Formula["portable-expat"]
    zlib = Formula["portable-zlib"]

    ENV.universal_binary if build.with? "universal"

    # Git Makefile doesn't support to link static libcurl.
    inreplace "Makefile", "$(CURL_LIBCURL)", `#{curl.opt_libexec/"curl-config"} --static-libs`.chomp
    ENV.append "LDFLAGS", "-L#{zlib.opt_prefix}/lib" if OS.linux?

    # If these things are installed, tell Git build system to not use them
    ENV["NO_FINK"] = "1"
    ENV["NO_DARWIN_PORTS"] = "1"
    ENV["V"] = "1" # build verbosely
    ENV["NO_R_TO_GCC_LINKER"] = "1" # pass arguments to LD correctly
    ENV["PYTHON_PATH"] = which "python"
    ENV["PERL_PATH"] = which "perl"
    ENV["NO_PERL_MAKEMAKER"] = "1"
    ENV["NO_GETTEXT"] = "1"
    ENV["NO_TCLTK"] = "1"
    if OS.linux? || OS::Mac.version < :leopard
      ENV["EXPATDIR"] = expat.opt_prefix
    end
    args = %W[
      prefix=#{prefix}
      CC=#{ENV.cc}
      CFLAGS=#{ENV.cflags}
      LDFLAGS=#{ENV.ldflags}
    ]
    system "make", "install", *args

    (libexec/"bin").mkpath
    (libexec/"bin").install bin/"git"
    (bin/"git").write <<~EOS
      #!/bin/bash
      GIT_LIBEXEC="$(cd "${0%/*}/.." && pwd -P)/libexec"
      GIT_SSL_CAINFO="$GIT_LIBEXEC/cert.pem" exec "$GIT_LIBEXEC/bin/git" "$@"
    EOS
    cp curl.opt_libexec/"cert.pem", libexec/"cert.pem"
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    ENV["PATH"] = "/usr/bin:/bin"
    ENV["GIT_CURL_VERBOSE"] = "1"
    system testpath/"bin/git", "clone", "https://github.com/isaacs/github"
  end
end
