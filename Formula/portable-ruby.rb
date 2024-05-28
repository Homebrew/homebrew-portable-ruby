require File.expand_path("../Abstract/portable-formula", __dir__)

class PortableRuby < PortableFormula
  desc "Powerful, clean, object-oriented scripting language"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.1.tar.gz"
  sha256 "8dc2af2802cc700cd182d5430726388ccf885b3f0a14fcd6a0f21ff249c9aa99"
  license "Ruby"

  # This regex restricts matching to versions other than X.Y.0.
  livecheck do
    formula "ruby"
    regex(/href=.*?ruby[._-]v?(\d+\.\d+\.(?:(?!0)\d+)(?:\.\d+)*)\.t/i)
  end

  depends_on "pkg-config" => :build
  depends_on "portable-libyaml" => :build
  depends_on "portable-openssl" => :build

  on_linux do
    depends_on "portable-libffi" => :build
    depends_on "portable-libxcrypt" => :build
    depends_on "portable-zlib" => :build
  end

  def install
    libyaml = Formula["portable-libyaml"]
    libxcrypt = Formula["portable-libxcrypt"]
    openssl = Formula["portable-openssl"]
    libffi = Formula["portable-libffi"]
    zlib = Formula["portable-zlib"]

    args = portable_configure_args + %W[
      --prefix=#{prefix}
      --enable-load-relative
      --with-static-linked-ext
      --with-out-ext=win32,win32ole
      --without-gmp
      --disable-install-doc
      --disable-install-rdoc
      --disable-dependency-tracking
    ]

    # We don't specify OpenSSL as we want it to use the pkg-config, which `--with-openssl-dir` will disable
    args += %W[
      --with-libyaml-dir=#{libyaml.opt_prefix}
    ]

    if OS.linux?
      ENV["XCFLAGS"] = "-I#{libxcrypt.opt_include}"
      ENV["XLDFLAGS"] = "-L#{libxcrypt.opt_lib}"

      args += %W[
        --with-libffi-dir=#{libffi.opt_prefix}
        --with-zlib-dir=#{zlib.opt_prefix}
      ]

      # Ensure compatibility with older Ubuntu when built with Ubuntu 22.04
      args << "MKDIR_P=/bin/mkdir -p"

      # Don't make libruby link to zlib as it means all extensions will require it
      # It's also not used with the older glibc we use anyway
      args << "ac_cv_lib_z_uncompress=no"
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
      make_args << "HAVE_BASERUBY=no"
      make_args << "PREP=miniruby"
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
        # Change e.g. `CONFIG["AR"] = "gcc-ar-11"` to `CONFIG["AR"] = "ar"`
        s.gsub!(/(CONFIG\[".+"\] = )"gcc-(.*)-\d+"/, '\\1"\\2"')
        # C++ compiler might have been disabled because we break it with glibc@2.13 builds
        s.sub!(/(CONFIG\["CXX"\] = )"false"/, '\\1"c++"')
      end
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
    assert_equal " \t\n`><=;|&{(",
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
