#!/bin/sh -x

# It will be run with two args: buildroot spec
BUILDROOT="$1"
SPEC="$2"

PRODUCT=unigine-superposition
PRODUCTDIR=/opt/unigine-superposition

. $(dirname $0)/common.sh

subst "s|^Group:.*|Group: Graphics|" $SPEC
subst "s|^License: unknown$|License: Proprietary|" $SPEC
subst "s|^URL:.*|URL: https://benchmark.unigine.com/superposition|" $SPEC
subst "s|^Summary:.*|Summary: Unigine Superposition (Unigine Benchmark)|" $SPEC

# move subdirs
mkdir -p $BUILDROOT$PRODUCTDIR/
for i in bin data docs ; do
    mv $BUILDROOT/$i $BUILDROOT$PRODUCTDIR/$i
    subst "s|\"/$i/|\"$PRODUCTDIR/$i/|" $SPEC
done

epm assure patchelf || exit

cd $BUILDROOT/$PRODUCTDIR || fatal
for i in bin/lib*.so ; do
    a= patchelf --set-rpath '$ORIGIN' $i
done

# pack icons
for i in 16 24 32 48 64 128 256 ; do
    mkdir -p $BUILDROOT/usr/share/icons/hicolor/${i}x${i}/apps/
    cp $BUILDROOT/icons/superposition_icon_$i.png $BUILDROOT/usr/share/icons/hicolor/${i}x${i}/apps/$PRODUCT.png
done
subst "s|%files|%files\n/usr/share/icons/hicolor/*x*/apps/$PRODUCT.png|" $SPEC
remove_dir /icons

# FIXME:
install_file /Superposition $PRODUCTDIR/Superposition
remove_file /Superposition
remove_file /Superposition.png
remove_file /postinstall.sh
remove_file /uninstall.sh
remove_file /version

# lib.req: ERROR: .../opt/unigine-superposition/bin/qt/lib/libssl.so: library libcrypto.so.1.0.0 not found
patchelf --remove-needed libcrypto.so.1.0.0 $BUILDROOT$PRODUCTDIR/bin/qt/lib/libssl.so

add_bin_exec_command superposition $PRODUCTDIR/bin/launcher
add_bin_link_command $PRODUCT /usr/bin/superposition

# create desktop file
mkdir -p $BUILDROOT/usr/share/applications/
cat <<EOF >$BUILDROOT/usr/share/applications/$PRODUCT.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Unigine Superposition 2017 Benchmark
GenericName=A GPU Stress test tool from the UNIGINE
Icon=$PRODUCT
Exec=superposition
Terminal=false
Categories=Launcher;Benchmark;
EOF

pack_file /usr/share/applications/$PRODUCT.desktop

epm install --skip-installed glib2 libdbus libEGL libGL libICE libqt5-test libSM libX11 libxcb libXext libXi libXinerama libXrandr libXrender zlib