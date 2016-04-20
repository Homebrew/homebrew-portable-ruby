module PortableFormulaInstall
  def install
    if OS.mac? && OS::Mac.version > :leopard
      opoo <<-EOS.undent
        You are building portable formula on #{OS::Mac.version}.
        As result, Ruby interpreter won't be able to work for OS X at lower version.
        It's recommended to build this formula on OS X Leopard.
      EOS
    end

    super
  end
end

class PortableFormula < Formula
  def self.inherited(subclass)
    subclass.class_eval do
      keg_only "Portable formula is keg-only."

      option "without-universal", "Don't build a universal binary" if OS.mac?

      prepend PortableFormulaInstall
    end
  end

  def archs
    if build.with? "universal"
      Hardware::CPU.universal_archs
    elsif OS::Mac.prefer_64_bit?
      [Hardware::CPU.arch_64_bit]
    else
      [Hardware::CPU.arch_32_bit]
    end
  end
end
