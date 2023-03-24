#!/bin/sh -x
# It will run with two args: buildroot spec
BUILDROOT="$1"
SPEC="$2"

PRODUCT="$(grep "^Name: " $SPEC | sed -e "s|Name: ||g" | head -n1)"
PRODUCTDIR=/opt/$PRODUCT

. $(dirname $0)/common.sh

# move package to /opt
ROOTDIR=$(basename $(find $BUILDROOT -mindepth 1 -maxdepth 1 -type d))
mkdir -p $BUILDROOT/opt
mv $BUILDROOT/$ROOTDIR $BUILDROOT$PRODUCTDIR
subst "s|\"/$ROOTDIR/|\"$PRODUCTDIR/|" $SPEC

fix_chrome_sandbox


cd $BUILDROOT$PRODUCTDIR

# TODO
if false ; then
# on whatsapp-for-linux example
epm assure patchelf || exit
# hack for
# ldd: ERROR: /var/tmp/tmp.kroKx0mR2G/whatsapp-for-linux-1.5.1-x86_64.AppImage.tmpdir/whatsapp-for-linux--1.5.1/opt/whatsapp-for-linux-/bin/systemd-hwdb: program interpreter /tmp/appimage-fcba8c70-fea2-41f2-8775-57ce8e19ffe9-ld-linux-x86-64.so.2 not found
find -executable -type f | while read elf ; do
    file $elf | grep -q "ELF 64-bit.*interpreter" || continue
    file $elf | grep -q "interpreter /lib64/ld-linux-x86-64.so.2" && continue
    a= patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 $elf
done

for i in usr/lib/x86_64-linux-gnu/*.so* lib/x86_64-linux-gnu/*.so* lib/x86_64-linux-gnu/security/*.so* opt/libc/lib/x86_64-linux-gnu/libc.so.6  ; do
    [ -s "$i" ] || continue
    a= patchelf --set-rpath '$ORIGIN:$ORIGIN/..:$ORIGIN/../../usr/lib/x86_64-linux-gnu:$ORIGIN/../../../usr/lib/x86_64-linux-gnu:' "$i"
    file $i | grep -q "ELF 64-bit.*interpreter" || continue
    file $i | grep -q "interpreter /lib64/ld-linux-x86-64.so.2" && continue
    a= patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 $i
done
fi

DESKTOPFILE="$(echo *.desktop | head -n1)"
FROMICONFILE=''

if [ -r "$DESKTOPFILE" ] ; then
    mkdir -p $BUILDROOT/usr/share/applications/
    cat $DESKTOPFILE | sed -e "s|AppRun|$PRODUCT|" -e 's|X-AppImage-Integrate.*||' > $BUILDROOT/usr/share/applications/$DESKTOPFILE
    pack_file /usr/share/applications/$DESKTOPFILE

    FROMICONFILE="$(cat $DESKTOPFILE | grep "^Icon" | head -n1 | sed -e 's|Icon=||').png"
fi

# it is strange, there is no icon file
# https://docs.appimage.org/reference/appdir.html
if [ ! -s "$FROMICONFILE" ] ; then
    FROMICONFILE=".DirIcon"
    ICONFILE="$PRODUCT.png"
    grep -q "^<svg" $FROMICONFILE && ICONFILE="$PRODUCT.svg"
fi
install_file $PRODUCTDIR/$FROMICONFILE /usr/share/pixmaps/$ICONFILE

# hack for remove MacOS only stuffs
remove_dir $(find $BUILDROOT -type d -name "*catalina*" | sed -e "s|$BUILDROOT||")

cd - >/dev/null

add_bin_exec_command $PRODUCT $PRODUCTDIR/AppRun
# Strange AppRun script uses args as path, so override path detection
subst "2iexport APPDIR=$PRODUCTDIR" $BUILDROOT/usr/bin/$PRODUCT

subst '1iAutoProv:no' $SPEC
#subst '1iAutoReq:yes,nopython,nomono,nomonolib' $SPEC
subst '1iAutoReq:no' $SPEC

# ignore embedded libs
drop_embedded_reqs
