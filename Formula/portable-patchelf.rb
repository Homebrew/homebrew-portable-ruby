class PortablePatchelf < Formula
  desc "Modify the dynamic linker and RPATH of ELF executables"
  homepage "https://nixos.org/patchelf.html"

  url "http://nixos.org/releases/patchelf/patchelf-0.9/patchelf-0.9.tar.gz"
  sha256 "f2aa40a6148cb3b0ca807a1bf836b081793e55ec9e5540a5356d800132be7e0a"

  head do
    url "https://github.com/NixOS/patchelf.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    # Fixes error: cannot find section
    # See https://github.com/NixOS/patchelf/pull/95
    inreplace "src/patchelf.cc",
      "string sectionName = getSectionName(shdr);",
      'string sectionName = getSectionName(shdr); if (sectionName == "") continue;'

    system "./bootstrap.sh" if build.head?
    system "./configure", "--prefix=#{prefix}",
      "CXXFLAGS=-static-libgcc -static-libstdc++",
      "--disable-debug", "--disable-dependency-tracking", "--disable-silent-rules"
    system "make", "install"
  end

  test do
    assert_match "syntax", shell_output("#{bin}/patchelf --help 2>&1")
  end
end
