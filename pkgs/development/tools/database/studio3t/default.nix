{ stdenv
, fetchurl
, makeDesktopItem
, makeWrapper
, unzip
, jre
}:

stdenv.mkDerivation rec {
  name = "studio3t-${version}";
  version = "5.0.1";
  homePage = "https://studio3t.com";
  downloadPage = homePage + "/download/";

  longName = "studio-3t";
  bitness = if stdenv.is64bit then "x64" else "x86";
  prefixWithBitness = "${longName}-${version}-linux-${bitness}";

  src = requireFile rec {
    name = "${longName}-linux-${bitness}.tar.gz";
    sha256 =
      if stdenv.is64bit
      then "72e6e8a695c908177fdb6aedd6b07d7516b6125fb2d0fad9cc1128150cfb7eb9"
      else "b20fd9c43798f2ebdd6b5d04caab88dca2d9674c2c90f62c6d48d87a7b37b123";
    message = ''
      In order to use Studio 3T, you need to comply with the EULA and download
      the file from:
      ${downloadPage}
      Once you have downloaded the file, please use the following command and re-run the
      installation:
      nix-prefetch-url file:///path/to/${name}
    '';
  };

  buildInputs = [
    jre makeWrapper stdenv unzip
  ];

  unpackPhase = ''
    tar -xzf ${src}
  '';

  buildPhase = ''
  '';

#  installPhase = ''
#    mkdir -p $out/share/squirrel-sql
#    cp -r . $out/share/squirrel-sql
#
#    mkdir -p $out/bin
#    cp=""
#    for pkg in ${builtins.concatStringsSep " " drivers}; do
#      if test -n "$cp"; then
#        cp="$cp:"
#      fi
#      cp="$cp"$(echo $pkg/share/java/*.jar | tr ' ' :)
#    done
#    makeWrapper $out/share/squirrel-sql/squirrel-sql.sh $out/bin/squirrel-sql \
#      --set CLASSPATH "$cp" \
#      --set JAVA_HOME "${jre}"
#
#    mkdir -p $out/share/icons/hicolor/32x32/apps
#    ln -s $out/share/squirrel-sql/icons/acorn.png \
#      $out/share/icons/hicolor/32x32/apps/squirrel-sql.png
#    ln -s ${desktopItem}/share/applications $out/share
#  '';

  installPhase = ''
    install -d $out/bin
    install -d $out/jre
    install -d $out/lib
    cp -r bin $out/bin
  '';

  desktopItem = makeDesktopItem {
    name = "studio-3t";
    exec = "studio-3t";
    comment = meta.description;
    desktopName = "Studio 3T";
    genericName = "MongoDB IDE";
    categories = "Development;";
    icon = "studio-3t";
  };

  meta = with stdenv.lib; {
    description = "MongoDB IDE";
    homepage = homePage;
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    maintainers = with stdenv.lib.maintainers; [ a1russell ];
  };
}
