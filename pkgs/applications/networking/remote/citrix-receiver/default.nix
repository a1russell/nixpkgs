# I get the following crash that the Debian guys get too:
#
# Error in wfica: corrupted double-linked list at memory address
# Documented here: https://www.reddit.com/r/debian/comments/34dkz7/debian_8_and_citrix_ica_client_corrupted/
#
# If you are able to fix this or have some clues that can help, please open an issue (and/or a pull request)
# on github and cc @obadz

{ stdenv
, requireFile
, makeWrapper
, libredirect
, busybox
, file
, makeDesktopItem
, tzdata
, cacert
, glib
, gtk
, atk
, gdk_pixbuf
, cairo
, pango
, gnome3
, xlibs
, libpng12
, freetype
, fontconfig
, gtk_engines
, alsaLib
, force32bit ? false }:

stdenv.mkDerivation rec {
  name = "citrix-receiver-13.2";

  use64bitVersion = stdenv.is64bit && !force32bit;
  prefixWithBitness = if use64bitVersion then "linuxx64" else "linuxx86";

  src = requireFile rec {
    name = "${prefixWithBitness}-13.2.1.328635.tar.gz";
    sha256 =
      if use64bitVersion
      then "3a11d663b1a11cc4ebb3e3595405d520ec279e1330462645c53edd5cc79d9ca0"
      else "16zxcbi75ss07ifmxs5yc97im20h4gcpdpdfy31k0vqvyf0j15jn";  # TODO: Update
    message = ''
      In order to use Citrix Receiver, you need to comply with the Citrix EULA and download
      the ${if use64bitVersion then "64-bit" else "32-bit"} binaries, .tar.gz from:

      https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-1321.html#ctx-dl-eula

      Once you have downloaded the file, please use the following command and re-run the
      installation:

      nix-prefetch-url file://${name}
    '';
  };

  #phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
  phases = [ "unpackPhase" "installPhase" ];

  sourceRoot = ".";

  buildInputs = [
    makeWrapper
    busybox
    file
    gtk
    gdk_pixbuf
  ];

  libPath = stdenv.lib.makeLibraryPath [
    glib
    gtk
    atk
    gdk_pixbuf
    cairo
    pango
    gnome3.dconf
    xlibs.libX11
    xlibs.libXext
    xlibs.libXrender
    xlibs.libXinerama
    xlibs.libXfixes
    libpng12
    gtk_engines
    freetype
    fontconfig
    alsaLib
    stdenv.cc.cc
  ];

  # debStuff = /home/david/vbox/opt/Citrix/ICAClient;
  desktopItem = makeDesktopItem {
    name = "wfica";
    desktopName = "Citrix Receiver";
    genericName = "Citrix Receiver";
    exec = "wfica";
    icon = "wfica";
    comment = "Connect to remote Citrix server";
    categories = "GTK;GNOME;X-GNOME-NetworkSettings;Network;";
    mimeType = "application/x-ica";
  };

  installPhase = ''
    export ICAInstDir="$out/opt/citrix-icaclient"

    # mkdir -v -p $ICAInstDir

    # cp -rv opt/Citrix/ICAClient/* $ICAInstDir/
    # cp -rv etc/icaclient/nls/en/* $ICAInstDir/config/
    # cp -rv etc/icaclient/config/* $ICAInstDir/config/

    # Missing the eula.txt causes nasty error:
    # Error: 75 (E_DYNLOAD_FAILED)
    # Please refer to the documentation.
    # Failed to load UIDialogLib:
    # /lib/UIDialogLib.so: cannot open shared object file: No such file or directory
    # cp -v opt/Citrix/ICAClient/nls/en.UTF-8/eula.txt $ICAInstDir

    # cp -rv {debStuff}/pkginf $ICAInstDir
    # cp -rv {debStuff}/config $ICAInstDir
    # cp -rv {debStuff}/eula.txt $ICAInstDir

    sed -i \
      -e 's,^main_install_menu$,install_ICA_client,g' \
      -e 's,^integrate_ICA_client(),alias integrate_ICA_client=true\nintegrate_ICA_client_old(),g' \
      -e 's,^ANSWER=""$,ANSWER="$INSTALLER_YES",' \
      -e 's,/bin/true,true,g' \
      ./${prefixWithBitness}/hinst

    # Run the installer...
    ./${prefixWithBitness}/hinst CDROM "`pwd`"

    echo "Deleting broken links..."
    for link in `find $ICAInstDir -type l `
    do
      [ -f "$link" ] || rm -v "$link"
    done

    echo "Patching executables..."
    find $ICAInstDir -type f -exec file {} \; |
      grep 'ELF.*executable' |
      cut -f 1 -d : |
      xargs -t -n 1 patchelf \
        --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
        --set-rpath "$ICAInstDir:$libPath"

    # echo "Installing desktop item..."
    # mkdir -pv $out/share/applications
    # cp -v usr/share/applications/* $out/share/applications/
    # for f in $out/share/applications/*
    # do
    #   substituteInPlace "$f" --replace "/opt/Citrix/ICAClient" "$ICAInstDir"
    # done

    echo "Expanding certificates..."
    # As explained in https://wiki.archlinux.org/index.php/Citrix#Security_Certificates
    pushd "$ICAInstDir/keystore/cacerts"
    awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "cert." c ".pem"}' < ${cacert}/etc/ssl/certs/ca-bundle.crt
    popd

    echo "Wrapping wfica..."
    mkdir "$out/bin"

    echo "Europe/London" > "$ICAInstDir/timezone"

    makeWrapper "$ICAInstDir/wfica -icaroot $ICAInstDir" "$out/bin/wfica" \
      --set ICAROOT "$ICAInstDir" \
      --set GTK_PATH "${gtk}/lib/gtk-2.0:${gnome3.gnome_themes_standard}/lib/gtk-2.0" \
      --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
      --set LD_PRELOAD "${libredirect}/lib/libredirect.so" \
      --set LD_LIBRARY_PATH $libPath \
      --set NIX_REDIRECTS "/usr/share/zoneinfo=${tzdata}/share/zoneinfo:/etc/zoneinfo=${tzdata}/share/zoneinfo:/etc/timezone=$ICAInstDir/timezone"
  '';

  meta = with stdenv.lib; {
    # license = stdenv.lib.licenses.unfree;
    homepage = "https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-131.html";
    description = "Citrix Receiver";
    maintainers = with maintainers; [ obadz ];
    platforms = platforms.linux;
  };
}
