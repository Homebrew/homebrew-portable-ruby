require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableRuby < PortableFormula
  desc "Powerful, clean, object-oriented scripting language"
  homepage "https://www.ruby-lang.org/"
  # This is the version shipped in macOS 11.7.1/12.6.1/13.
  url "https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.10.tar.xz"
  sha256 "5fd8ded51321b88fdc9c1b4b0eb1b951d2eddbc293865da0151612c2e814c1f2"
  license "Ruby"

  depends_on "pkg-config" => :build
  depends_on "portable-libyaml" => :build
  depends_on "portable-openssl" => :build

  on_linux do
    depends_on "portable-libedit" => :build
    depends_on "portable-libxcrypt" => :build
    depends_on "portable-ncurses" => :build
    depends_on "portable-zlib" => :build
  end

  def install
    libedit = Formula["portable-libedit"]
    libyaml = Formula["portable-libyaml"]
    openssl = Formula["portable-openssl"]
    libxcrypt = Formula["portable-libxcrypt"]
    ncurses = Formula["portable-ncurses"]
    zlib = Formula["portable-zlib"]

    args = portable_configure_args + %W[
      --prefix=#{prefix}
      --enable-load-relative
      --with-static-linked-ext
      --with-out-ext=tk,sdbm,gdbm,dbm
      --without-gmp
      --enable-libedit
      --disable-install-doc
      --disable-install-rdoc
      --disable-dependency-tracking
    ]

    # Correct MJIT_CC to not use superenv shim
    args << "MJIT_CC=/usr/bin/#{DevelopmentTools.default_compiler}"

    args += %W[
      --with-libedit-dir=#{libedit.opt_prefix}
      --with-libyaml-dir=#{libyaml.opt_prefix}
      --with-openssl-dir=#{openssl.opt_prefix}
    ]

    if OS.linux?
      ENV["XCFLAGS"] = "-I#{libxcrypt.opt_include}"
      ENV["XLDFLAGS"] = "-L#{libxcrypt.opt_lib}"

      # We want Ruby to link to our ncurses, instead of libtermcap in CentOS 5
      inreplace "ext/readline/extconf.rb" do |s|
        s.gsub! "dir_config('termcap')", ""
        s.gsub! 'have_library("termcap", "tgetnum") ||', ""
      end

      args += %W[
        --with-ncurses-dir=#{ncurses.opt_prefix}
        --with-zlib-dir=#{zlib.opt_prefix}
      ]
    end

    # Append flags rather than override
    ENV["cflags"] = ENV.delete("CFLAGS")
    ENV["cppflags"] = ENV.delete("CPPFLAGS")
    ENV["cxxflags"] = ENV.delete("CXXFLAGS")

    # Usually cross-compiling requires a host Ruby of the same version.
    # In our scenario though, we can get away with using miniruby as it should run on newer macOS.
    if OS.mac? && CROSS_COMPILING
      ENV["MINIRUBY"] = "./miniruby -I$(srcdir)/lib -I. -I$(EXTOUT)/common"
      run_opts = "#{Dir.pwd}/tool/runruby.rb --extout=.ext"
    end

    system "./configure", *args
    system "make", "RUN_OPTS=#{run_opts}"
    system "make", "install", "RUN_OPTS=#{run_opts}"

    # rake is a binstub for the RubyGem in 2.3 and has a hardcoded PATH.
    # We don't need the binstub so remove it.
    rm bin/"rake"

    abi_version = `#{bin}/ruby -rrbconfig -e 'print RbConfig::CONFIG["ruby_version"]'`
    abi_arch = `#{bin}/ruby -rrbconfig -e 'print RbConfig::CONFIG["arch"]'`

    if OS.linux?
      # Don't restrict to a specific GCC compiler binary we used (e.g. gcc-5).
      inreplace lib/"ruby/#{abi_version}/#{abi_arch}/rbconfig.rb" do |s|
        s.gsub! ENV.cxx, "c++"
        s.gsub! ENV.cc, "cc"
      end

      cp_r ncurses.share/"terminfo", share/"terminfo"
    end

    libexec.mkpath
    cp openssl.libexec/"etc/openssl/cert.pem", libexec/"cert.pem"
    openssl_rb = lib/"ruby/#{abi_version}/openssl.rb"
    inreplace openssl_rb, "require 'openssl.so'", <<~EOS.chomp
      ENV["SSL_CERT_FILE"] ||= File.expand_path("../../libexec/cert.pem", RbConfig.ruby)
      \\0
    EOS
  end

  test do
    cp_r Dir["#{prefix}/*"], testpath
    ENV["PATH"] = "/usr/bin:/bin"
    ruby = (testpath/"bin/ruby").realpath
    assert_equal version.to_s.split("-").first, shell_output("#{ruby} -e 'puts RUBY_VERSION'").chomp
    assert_equal ruby.to_s, shell_output("#{ruby} -e 'puts RbConfig.ruby'").chomp
    assert_equal "3632233996",
      shell_output("#{ruby} -rzlib -e 'puts Zlib.crc32(\"test\")'").chomp
    assert_equal " \t\n\"\\'`@$><=;|&{(",
      shell_output("#{ruby} -rreadline -e 'puts Readline.basic_word_break_characters'").chomp
    assert_equal '{"a"=>"b"}',
      shell_output("#{ruby} -ryaml -e 'puts YAML.load(\"a: b\")'").chomp
    assert_equal "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      shell_output("#{ruby} -ropenssl -e 'puts OpenSSL::Digest::SHA256.hexdigest(\"\")'").chomp
    assert_match "200",
      shell_output("#{ruby} -ropen-uri -e 'open(\"https://google.com\") { |f| puts f.status.first }'").chomp
    system testpath/"bin/gem", "environment"
    system testpath/"bin/bundle", "init"
    # install gem with native components
    system testpath/"bin/gem", "install", "byebug"
    assert_match "byebug",
      shell_output("#{testpath}/bin/byebug --version")
  end
end
