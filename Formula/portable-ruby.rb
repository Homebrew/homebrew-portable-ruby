require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableRuby < PortableFormula
  desc "Portable ruby"
  homepage "https://www.ruby-lang.org/"
  url "https://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p648.tar.bz2"
  sha256 "087ad4dec748cfe665c856dbfbabdee5520268e94bb81a1d8565d76c3cc62166"

  depends_on "makedepend" => :build
  depends_on "pkg-config" => :build
  depends_on "portable-readline" => :build
  depends_on "portable-libyaml" => :build
  depends_on "portable-openssl" => :build

  def install
    ENV.append "LDFLAGS", "-Wl,-search_paths_first"

    readline = Formula["portable-readline"]
    libyaml = Formula["portable-libyaml"]
    openssl = Formula["portable-openssl"]

    args = %W[
      --prefix=#{prefix}
      --enable-load-relative
      --with-static-linked-ext
      --disable-dln
      --with-out-ext=tk,sdbm,gdbm,dbm,dl,coverage
      --disable-install-doc
      --disable-install-rdoc
      --disable-dtrace
    ]

    if build.with? "universal"
      ENV.universal_binary
      args << "--with-arch=#{archs.join(",")}"
    end

    paths = [
      readline.opt_prefix,
      libyaml.opt_prefix,
      openssl.opt_prefix,
    ]

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
    (testpath/"test_openssl_cert.rb").write <<-'EOS'.undent
      require "socket"
      require "openssl"

      context = OpenSSL::SSL::SSLContext.new
      tcp_client = TCPSocket.new "www.google.com", 443
      ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
      ssl_client.connect
      ssl_client.write "GET / HTTP/1.1\r\n\r\n"
      puts ssl_client.gets
    EOS
    assert_match "HTTP/1.1", shell_output("#{ruby} #{testpath}/test_openssl_cert.rb")
    system testpath/"bin/gem", "environment"
    system testpath/"bin/gem", "install", "bundler"
    system testpath/"bin/bundle", "init"
  end
end
