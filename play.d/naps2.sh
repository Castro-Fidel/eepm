#!/bin/sh

PKGNAME=naps2
SUPPORTEDARCHES="x86_64 aarch64"
VERSION="$2"
DESCRIPTION="Scan documents to PDF and more, as simply as possible."
URL="https://github.com/cyanfish/naps2/releases/"

. $(dirname $0)/common.sh

arch="$(epm print info -a)"
case "$arch" in
    x86_64)
        arch=x64
	;;
    aarch64)
        arch=arm64
        ;;
esac

pkgtype=$(epm print info -p)

if [ "$pkgtype" == "deb" ] || [ "$pkgtype" == "rpm" ] ; then
    pkgtype="$pkgtype"
else
    pkgtype="deb"
fi

PKGURL=$(eget --list --latest https://github.com/cyanfish/naps2/releases "$PKGNAME-$VERSION-linux-$arch.$pkgtype")


install_pkgurl