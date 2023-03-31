#!/bin/sh

PKGNAME=apache-netbeans
#SUPPORTEDARCHES="x86_64"
DESCRIPTION="Apache NetBeans 17 from the official site"

. $(dirname $0)/common.sh

pkgtype=$(epm print info -p)
case $pkgtype in
    rpm)
        mask="apache-netbeans-*.noarch.rpm"
        ;;
    *)
        mask="apache-netbeans_*_all.deb"
        ;;
esac

epm install "https://dlcdn.apache.org/netbeans/netbeans-installers/17/$mask"