require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableRuby < PortableFormula
  desc "Portable ruby"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p648.tar.bz2"
  sha256 "087ad4dec748cfe665c856dbfbabdee5520268e94bb81a1d8565d76c3cc62166"

  bottle do
    cellar :any_skip_relocation
    sha256 "5c1240abe4be91c9774a0089c2a38a8ccfff87c009e8e5786730c659d5e633f7" => :leopard_64
    sha256 "dbb5118a22a6a75cc77e62544a3d8786d383fab1bdaf8c154951268807357bf0" => :x86_64_linux
  end

  depends_on "makedepend" => :build
  depends_on "pkg-config" => :build
  depends_on "portable-readline" => :build
  depends_on "portable-libyaml" => :build
  depends_on "portable-openssl" => :build
  depends_on "portable-ncurses" => :build if OS.linux?

  def install
    ENV.append "LDFLAGS", "-Wl,-search_paths_first"

    readline = Formula["portable-readline"]
    libyaml = Formula["portable-libyaml"]
    openssl = Formula["portable-openssl"]
    ncurses = Formula["portable-ncurses"]

    args = %W[
      --prefix=#{prefix}
      --enable-load-relative
      --with-static-linked-ext
      --disable-dln
      --with-out-ext=tk,sdbm,gdbm,dbm,dl,coverage,fiddle
      --disable-install-doc
      --disable-install-rdoc
      --disable-dtrace
    ]

    if OS.mac?
      if build.with? "universal"
        ENV.universal_binary
      else
        ENV.permit_arch_flags
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
      inreplace "ext/curses/extconf.rb" do |s|
        s.gsub! "dir_config('termcap')", ""
        s.gsub! 'or have_library("termcap", "tgetent")', ""
      end
    end

    args << "--with-opt-dir=#{paths.join(":")}"

    system "./configure", *args
    system "make"
    system "make", "install"

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
  end
end
