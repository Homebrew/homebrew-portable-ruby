class PortableBerkeleyDb < PortableFormula
  desc "High performance key/value database"
  homepage "https://www.oracle.com/technology/products/berkeley-db/index.html"
  url "https://download.oracle.com/berkeley-db/db-6.2.32.tar.gz"
  sha256 "a9c5e2b004a5777aa03510cfe5cd766a4a3b777713406b02809c17c8e0e7a8fb"

  def install
    # BerkeleyDB dislikes parallel builds
    ENV.deparallelize
    
    # --enable-compat185 is necessary because our build shadows
    # the system berkeley db 1.x
    args = %W[
      --disable-shared
      --disable-debug
      --prefix=#{prefix}
      --mandir=#{man}
      --enable-cxx
      --enable-compat185
      --enable-sql
      --enable-sql_codegen
      --enable-dbm
      --enable-stl
    ]

    # BerkeleyDB requires you to build everything from the build_unix subdirectory
    cd "build_unix" do
      system "../dist/configure", *args
      system "make", "install"

      # use the standard docs location
      doc.parent.mkpath
      mv prefix/"docs", doc
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <assert.h>
      #include <string.h>
      #include <db_cxx.h>
      int main() {
        Db db(NULL, 0);
        assert(db.open(NULL, "test.db", NULL, DB_BTREE, DB_CREATE, 0) == 0);

        const char *project = "Homebrew";
        const char *stored_description = "The missing package manager for macOS";
        Dbt key(const_cast<char *>(project), strlen(project) + 1);
        Dbt stored_data(const_cast<char *>(stored_description), strlen(stored_description) + 1);
        assert(db.put(NULL, &key, &stored_data, DB_NOOVERWRITE) == 0);

        Dbt returned_data;
        assert(db.get(NULL, &key, &returned_data, 0) == 0);
        assert(strcmp(stored_description, (const char *)(returned_data.get_data())) == 0);

        assert(db.close(0) == 0);
      }
    EOS
    flags = %W[
      -I#{include}
      -L#{lib}
      -ldb_cxx
    ]
    system ENV.cxx, "test.cpp", "-o", "test", *flags
    system "./test"
    assert_predicate testpath/"test.db", :exist?
  end
end
