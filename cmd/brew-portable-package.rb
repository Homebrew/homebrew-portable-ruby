require "formula"
require "keg"

include FileUtils

def tag(f)
  if OS.mac?
    kernel_version = `uname -r`.split(".").first
    if f.build.with? "universal"
      "universal-darwin#{kernel_version}"
    else
      "#{f.archs.first}-darwin#{kernel_version}"
    end
  else
    "x86_64-linux"
  end
end

raise FormulaUnspecifiedError if ARGV.named.empty?
f = ARGV.resolved_formulae.first
keg = Keg.new f.prefix
tab = Tab.for_keg(keg)
f.build = tab
filename = "#{f.name}-#{f.pkg_version}.#{tag(f)}.tar.gz"
bottle_path = Pathname.pwd/filename
tar_filename = filename.to_s.sub(/.gz$/, "")
tar_path = Pathname.pwd/tar_filename

ohai "Packaging #{filename}..."
keg.lock do
  begin
    original_tab = tab.dup
    tab.poured_from_bottle = false
    tab.HEAD = nil
    tab.time = nil
    tab.write

    keg.find do |file|
      if file.symlink?
        # Ruby does not support `File.lutime` yet.
        # Shellout using `touch` to change modified time of symlink itself.
        system "/usr/bin/touch", "-h",
               "-t", tab.source_modified_time.strftime("%Y%m%d%H%M.%S"), file
      else
        file.utime(tab.source_modified_time, tab.source_modified_time)
      end
    end

    cd HOMEBREW_CELLAR do
      safe_system "tar", "cf", tar_path, "#{f.name}/#{f.pkg_version}"
      tar_path.utime(tab.source_modified_time, tab.source_modified_time)
      relocatable_tar_path = "#{f}-bottle.tar"
      mv tar_path, relocatable_tar_path
      safe_system "gzip", "-f", relocatable_tar_path
      mv "#{relocatable_tar_path}.gz", bottle_path
    end
  ensure
    ignore_interrupts do
      original_tab.write
    end
  end
end
