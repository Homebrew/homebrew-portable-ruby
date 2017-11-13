require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableRuby < PortableFormula
  desc "Portable ruby"
  homepage "https://www.ruby-lang.org/"
  # Tracks the 2.3 maintenance branch.
  # We don't need to update for every new commit in this branch;
  # we should update when something important comes up though.
  url "https://github.com/ruby/ruby.git",
    :revision => "463a56d14b9241c8631d71d286760ea092d70c36"
  version "2.3-2017-09-15"

  bottle do
    cellar :any_skip_relocation
    rebuild 1
    sha256 "34ce9e4c9c1be28db564d744165aa29291426f8a3d2ef806ba4f0b9175aedb2b" => :leopard_64_or_later
  end

  depends_on "autoconf" => :build
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

    readline = Formula["portable-readline"]
    libyaml = Formula["portable-libyaml"]
    openssl = Formula["portable-openssl"]
    ncurses = Formula["portable-ncurses"]
    zlib = Formula["portable-zlib"]

    args = %W[
      --prefix=#{prefix}
      --enable-load-relative
      --with-static-linked-ext
      --with-out-ext=tk,sdbm,gdbm,dbm,dl,fiddle
      --disable-install-doc
      --disable-install-rdoc
      --disable-dtrace
    ]

    if OS.mac?
      if build.with?("universal") && MacOS.version < :snow_leopard && !superenv?
        # This will break the 32-bit PPC slice otherwise (this is only
        # necessary on stdenv)
        ENV.replace_in_cflags(/-march=\S*/, "-Xarch_i386 \\0")
        ENV.replace_in_cflags(/-mcpu=\S*/, "-Xarch_ppc \\0")
      end
      args << "--with-arch=#{archs.join(",")}"
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

    system "autoconf"

    system "./configure", *args
    make
    make "install"

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
    openssl_rb.write <<-EOS.undent
      ENV["SSL_CERT_FILE"] ||= File.expand_path("../../libexec/cert.pem", RbConfig.ruby)
      #{openssl_rb_content}
    EOS
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    ENV["PATH"] = "/usr/bin:/bin"
    ruby = (testpath/"bin/ruby").realpath
    assert_equal version.to_s.split("-").first, shell_output("#{ruby} -e 'puts RUBY_VERSION'").strip.rpartition(".")[0]
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
