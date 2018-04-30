require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableRuby < PortableFormula
  desc "Portable ruby"
  homepage "https://www.ruby-lang.org/"
  # This isn't the latest 2.3.3 but is the version shipped in macOS 10.13.
  url "https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.3.tar.bz2"
  mirror "http://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.3.tar.bz2"
  sha256 "882e6146ed26c6e78c02342835f5d46b86de95f0dc4e16543294bc656594cc5b"
  revision 1

  bottle do
    cellar :any_skip_relocation
    sha256 "a7f8ebcae0a3d88b3f1d9fd1ff77330b64a52a4fb5cbf25e3e02bec0211cbe23" => :leopard_64_or_later
  end

  depends_on "make" => :build if OS.mac? && MacOS.version < :leopard
  depends_on "makedepend" => :build
  depends_on "pkg-config" => :build
  depends_on "portable-readline" => :build
  depends_on "portable-libyaml" => :build
  depends_on "portable-openssl" => :build
  if OS.linux?
    depends_on "portable-ncurses" => :build
    depends_on "portable-zlib" => :build
  end

  # Fixes the static build: https://bugs.ruby-lang.org/issues/13413
  # This has been backported into the 2.3 branch, but isn't in the
  # release we're building.
  patch do
    url "https://github.com/ruby/ruby/commit/b3dbeb6e90f316584f70e33f6bfb9d83fa5f30d3.patch?full_index=1"
    mirror "https://cdn.rawgit.com/sjackman/1b1a420c39f33512d4ed8129277ba1d2/raw/1cfd510dad86f835092e6ab18528e8cee5e801a2/b3dbeb6e90f316584f70e33f6bfb9d83fa5f30d3.patch"
    sha256 "17a6a37e500f3455bb85e6bd4b077228d7a32f63bf07ecf67248acbd3a5ea724"
  end

  # Fixes the build of dir.c on 10.5 due to missing fgetattrlist:
  # https://bugs.ruby-lang.org/issues/13573
  # This has been backported into the 2.3 branch, but isn't in the
  # release we're building.
  patch do
    url "https://github.com/ruby/ruby/commit/1c80c388d5bd48018c419a2ea3ed9f7b7514dfa3.patch?full_index=1"
    mirror "https://cdn.rawgit.com/sjackman/1b1a420c39f33512d4ed8129277ba1d2/raw/1cfd510dad86f835092e6ab18528e8cee5e801a2/1c80c388d5bd48018c419a2ea3ed9f7b7514dfa3.patch"
    sha256 "8ba0a24a36702d2cbc94aa73cb6f0b11793348b0158c11c8608e073c71601bb5"
  end

  def install
    # mcontext types had a member named `ss` instead of `__ss`
    # prior to Leopard; see
    # https://github.com/mistydemeo/tigerbrew/issues/473
    if OS.mac? && Hardware::CPU.intel? && MacOS.version < :leopard
      inreplace "signal.c" do |s|
        s.gsub! "->__ss.", "->ss."
        s.gsub! "__rsp", "rsp"
        s.gsub! "__esp", "esp"
      end

      inreplace "vm_dump.c" do |s|
        s.gsub! /uc_mcontext->__(ss)\.__(r\w\w)/,
                "uc_mcontext->\1.\2"
        s.gsub! "mctx->__ss.__##reg",
                "mctx->ss.reg"
        # missing include in vm_dump; this is an ugly solution
        s.gsub! '#include "iseq.h"',
                %Q(#include "iseq.h"\n#include <ucontext.h>)
      end
    end

    # Fixes includedir inappropriately prefixed with SDKROOT:
    # https://bugs.ruby-lang.org/issues/13572
    # This has been backported into the 2.3 branch, but isn't in the
    # release we're building and can't be cherry-picked cleanly.
    inreplace "tool/mkconfig.rb",
              "when /^includedir$/",
              "when /^oldincludedir$/"

    readline = Formula["portable-readline"]
    libyaml = Formula["portable-libyaml"]
    openssl = Formula["portable-openssl"]
    ncurses = Formula["portable-ncurses"]
    zlib = Formula["portable-zlib"]

    args = %W[
      --prefix=#{prefix}
      --enable-load-relative
      --with-static-linked-ext
      --with-out-ext=tk
      --disable-install-doc
      --disable-install-rdoc
      --disable-dependency-tracking
    ]

    if OS.mac?
      if build.with?("universal") && MacOS.version < :snow_leopard && !superenv?
        # This will break the 32-bit PPC slice otherwise (this is only
        # necessary on stdenv)
        ENV.replace_in_cflags(/-march=\S*/, "-Xarch_i386 \\0")
        ENV.replace_in_cflags(/-mcpu=\S*/, "-Xarch_ppc \\0")
      end

      args << "--with-arch=#{archs.join(",")}"

      # DTrace support doesn't build on 10.5 :(
      args << "--disable-dtrace"
    end

    paths = [
      readline.opt_prefix,
      libyaml.opt_prefix,
      openssl.opt_prefix,
    ]

    if OS.linux?
      # We want Ruby to link to our ncurses, instead of libtermcap in CentOS 5
      paths << ncurses.opt_prefix
      inreplace "ext/readline/extconf.rb" do |s|
        s.gsub! "dir_config('termcap')", ""
        s.gsub! 'have_library("termcap", "tgetnum") ||', ""
      end

      paths << zlib.opt_prefix
    end

    args << "--with-opt-dir=#{paths.join(":")}"

    system "./configure", *args
    make
    make "install"

    # rake is a binstub for the RubyGem in 2.3 and has a hardcoded PATH.
    # We don't need the binstub so remove it.
    rm bin/"rake"

    abi_version = `#{bin}/ruby -rrbconfig -e 'print RbConfig::CONFIG["ruby_version"]'`
    abi_arch = `#{bin}/ruby -rrbconfig -e 'print RbConfig::CONFIG["arch"]'`
    inreplace lib/"ruby/#{abi_version}/#{abi_arch}/rbconfig.rb" do |s|
      s.gsub! ENV.cxx, "c++"
      s.gsub! ENV.cc, "cc"
    end

    libexec.mkpath
    cp openssl.opt_libexec/"etc/openssl/cert.pem", libexec/"cert.pem"
    openssl_rb = lib/"ruby/#{abi_version}/openssl.rb"
    openssl_rb_content = openssl_rb.read
    rm openssl_rb
    openssl_rb.write <<~EOS
      ENV["SSL_CERT_FILE"] ||= File.expand_path("../../libexec/cert.pem", RbConfig.ruby)
      #{openssl_rb_content}
    EOS
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    ENV["PATH"] = "/usr/bin:/bin"
    ruby = (testpath/"bin/ruby").realpath
    assert_equal version.to_s.split("-").first, shell_output("#{ruby} -e 'puts RUBY_VERSION'").strip
    assert_equal ruby.to_s, shell_output("#{ruby} -e 'puts RbConfig.ruby'").strip
    assert_equal "3632233996",
      shell_output("#{ruby} -rzlib -e 'puts Zlib.crc32(\"test\")'").strip
    assert_equal "\"'",
      shell_output("#{ruby} -rreadline -e 'puts Readline.basic_quote_characters'").strip
    assert_equal '{"a"=>"b"}',
      shell_output("#{ruby} -ryaml -e 'puts YAML.load(\"a: b\")'").strip
    assert_equal "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      shell_output("#{ruby} -ropenssl -e 'puts OpenSSL::Digest::SHA256.hexdigest(\"\")'").strip
    assert_match "200",
      shell_output("#{ruby} -ropen-uri -e 'open(\"https://google.com\") { |f| puts f.status.first }'").strip
    system testpath/"bin/gem", "environment"
    system testpath/"bin/gem", "install", "bundler"
    system testpath/"bin/bundle", "init"
    # install gem with native components
    system testpath/"bin/gem", "install", "byebug"
    assert_match "byebug",
      shell_output("#{testpath}/bin/byebug --version")
  end
end
