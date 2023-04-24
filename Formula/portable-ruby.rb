require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableRuby < PortableFormula
  desc "Powerful, clean, object-oriented scripting language"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz"
  sha256 "96c57558871a6748de5bc9f274e93f4b5aad06cd8f37befa0e8d94e7b8a423bc"
  license "Ruby"
  revision 1

  depends_on "pkg-config" => :build
  depends_on "portable-libyaml" => :build
  depends_on "portable-openssl" => :build

  on_linux do
    depends_on "portable-libedit" => :build
    depends_on "portable-libffi" => :build
    depends_on "portable-libxcrypt" => :build
    depends_on "portable-ncurses" => :build
    depends_on "portable-zlib" => :build
  end

  # Fix macOS 10.11 compile
  patch :DATA

  def install
    libyaml = Formula["portable-libyaml"]
    openssl = Formula["portable-openssl"]
    libxcrypt = Formula["portable-libxcrypt"]
    libedit = Formula["portable-libedit"]
    libffi = Formula["portable-libffi"]
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
        --with-libedit-dir=#{libedit.opt_prefix}
        --with-libffi-dir=#{libffi.opt_prefix}
        --with-ncurses-dir=#{ncurses.opt_prefix}
        --with-zlib-dir=#{zlib.opt_prefix}
      ]

      # Ensure compatibility with older Ubuntu when built with Ubuntu 22.04
      args << "MKDIR_P=/bin/mkdir -p"
    end

    # Append flags rather than override
    ENV["cflags"] = ENV.delete("CFLAGS")
    ENV["cppflags"] = ENV.delete("CPPFLAGS")
    ENV["cxxflags"] = ENV.delete("CXXFLAGS")

    # Usually cross-compiling requires a host Ruby of the same version.
    # In our scenario though, we can get away with using miniruby as it should run on newer macOS.
    make_args = []
    if OS.mac? && CROSS_COMPILING
      ENV["MINIRUBY"] = "./miniruby -I$(srcdir)/lib -I. -I$(EXTOUT)/common"
      make_args << "BOOTSTRAPRUBY=#{ENV["MINIRUBY"]}"
      make_args << "BOOTSTRAPRUBY_OPT="
      make_args << "BOOTSTRAPRUBY_FAKE="
      make_args << "RUN_OPTS=#{Dir.pwd}/tool/runruby.rb --extout=.ext"
    end

    system "./configure", *args
    system "make", *make_args
    system "make", "install", *make_args

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
      ENV["PORTABLE_RUBY_SSL_CERT_FILE"] = ENV["SSL_CERT_FILE"] || File.expand_path("../../libexec/cert.pem", RbConfig.ruby)
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
      shell_output("#{ruby} -ropen-uri -e 'URI.open(\"https://google.com\") { |f| puts f.status.first }'").chomp
    system testpath/"bin/gem", "environment"
    system testpath/"bin/bundle", "init"
    # install gem with native components
    system testpath/"bin/gem", "install", "byebug"
    assert_match "byebug",
      shell_output("#{testpath}/bin/byebug --version")
  end
end

__END__
diff --git a/process.c b/process.c
index dbe2be5b56..c91390d030 100644
--- a/process.c
+++ b/process.c
@@ -8361,9 +8361,12 @@ rb_clock_gettime(int argc, VALUE *argv, VALUE _)
 
     VALUE unit = (rb_check_arity(argc, 1, 2) == 2) ? argv[1] : Qnil;
     VALUE clk_id = argv[0];
+#if defined(HAVE_CLOCK_GETTIME)
     clockid_t c;
+#endif
 
     if (SYMBOL_P(clk_id)) {
+#if defined(HAVE_CLOCK_GETTIME)
 #ifdef CLOCK_REALTIME
         if (clk_id == RUBY_CLOCK_REALTIME) {
             c = CLOCK_REALTIME;
@@ -8390,6 +8393,7 @@ rb_clock_gettime(int argc, VALUE *argv, VALUE _)
             c = CLOCK_THREAD_CPUTIME_ID;
             goto gettime;
         }
+#endif
 #endif
 
         /*
@@ -8587,12 +8591,15 @@ rb_clock_getres(int argc, VALUE *argv, VALUE _)
     timetick_int_t denominators[2];
     int num_numerators = 0;
     int num_denominators = 0;
+#if defined(HAVE_CLOCK_GETRES)
     clockid_t c;
+#endif
 
     VALUE unit = (rb_check_arity(argc, 1, 2) == 2) ? argv[1] : Qnil;
     VALUE clk_id = argv[0];
 
     if (SYMBOL_P(clk_id)) {
+#if defined(HAVE_CLOCK_GETRES)
 #ifdef CLOCK_REALTIME
         if (clk_id == RUBY_CLOCK_REALTIME) {
             c = CLOCK_REALTIME;
@@ -8620,6 +8627,7 @@ rb_clock_getres(int argc, VALUE *argv, VALUE _)
             goto getres;
         }
 #endif
+#endif
 
 #ifdef RUBY_GETTIMEOFDAY_BASED_CLOCK_REALTIME
         if (clk_id == RUBY_GETTIMEOFDAY_BASED_CLOCK_REALTIME) {
