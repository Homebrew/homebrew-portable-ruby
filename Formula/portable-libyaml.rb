require File.expand_path("../../Abstract/portable-formula", __FILE__)

class PortableLibyaml < PortableFormula
  desc "Portable libyaml"
  homepage "http://pyyaml.org/wiki/LibYAML"
  url "http://pyyaml.org/download/libyaml/yaml-0.1.6.tar.gz"
  mirror "https://mirrors.kernel.org/debian/pool/main/liby/libyaml/libyaml_0.1.6.orig.tar.gz"
  sha256 "7da6971b4bd08a986dd2a61353bc422362bd0edcc67d7ebaac68c95f74182749"

  # address CVE-2014-9130
  # https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-9130
  patch do
    url "https://bitbucket.org/xi/libyaml/commits/2b9156756423e967cfd09a61d125d883fca6f4f2/raw/"
    sha256 "30546a280c4f9764a93ff5f4f88671a02222e9886e7f63ee19aebf1b2086a7fe"
  end

  def install
    ENV.universal_binary if build.with? "universal"
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end
end
