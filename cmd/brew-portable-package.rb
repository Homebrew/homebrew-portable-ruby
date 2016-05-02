require "formula"
require "keg"

include FileUtils

raise FormulaUnspecifiedError if ARGV.named.empty?
f = ARGV.formulae.first
keg = Keg.new f.prefix
filename = "#{f.name}-#{f.pkg_version}.tar.gz"
tar_filename = filename.to_s.sub(/.gz$/, "")
tar_path = Pathname.pwd/tar_filename

ohai "Packaging #{filename}..."
keg.lock do
  begin
    Tab.clear_cache
    tab = Tab.for_keg(keg)
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

    cd f.rack do
      safe_system "tar", "cf", tar_path, f.pkg_version
      tar_path.utime(tab.source_modified_time, tab.source_modified_time)
      safe_system "gzip", "-f", tar_path
    end
  ensure
    ignore_interrupts do
      original_tab.write
    end
  end
end
