#!/bin/bash

set -e

absolutize ()
{
  if [ ! -d "$1" ]; then
    echo
    echo "ERROR: '$1' doesn't exist or not a directory!"
    kill -INT $$
  fi

  pushd "$1" >/dev/null
  echo `pwd`
  popd >/dev/null
}

TARGET_PLATFORM=$1

if [ -z ${TARGET_PLATFORM} ]; then
    echo "Usage: $0 target-platform (e.g. 'TLWDR4300')"
    kill -INT $$
fi

case $TARGET_PLATFORM in
WNDR3700)
  ARCH="ar71xx"
  ARCH2="-generic"
  ;;
Mamba)
  ARCH="mvebu"
  ARCH2=""
  ;;
*)
  echo "Unexpected platform"
  exit 1
  ;;
esac

REL="-rc3"
REL=""
BUILD=`dirname "$0"`"/build/"
BUILD=`absolutize $BUILD`
IMGTEMPDIR="${BUILD}/openwrt-build-image-extras"
IMGFILE="OpenWrt-ImageBuilder-15.05${REL}-${ARCH}${ARCH2}.Linux-x86_64.tar.bz2"
IMGBUILDERDIR="${BUILD}/OpenWrt-ImageBuilder-15.05${REL}-${ARCH}${ARCH2}.Linux-x86_64"
IMGBUILDERURL="https://downloads.openwrt.org/chaos_calmer/15.05${REL}/${ARCH}/generic/${IMGFILE}"

PREINSTALLED_PACKAGES="wireless-tools firewall iptables"
PREINSTALLED_PACKAGES+=" ppp ppp-mod-pppoe ppp-mod-pppol2tp ppp-mod-pptp kmod-ppp kmod-pppoe"
PREINSTALLED_PACKAGES+=" fdisk blkid swap-utils mount-utils block-mount e2fsprogs kmod-fs-ext4 kmod-usb2 kmod-usb-uhci kmod-usb-ohci kmod-usb-storage kmod-usb-storage-extras kmod-mmc"
PREINSTALLED_PACKAGES+=" luci"

mkdir --parents ${BUILD}

rm -rf $IMGTEMPDIR
cp -r image-extras/common $IMGTEMPDIR
PER_PLATFORM_IMAGE_EXTRAS=image-extras/${TARGET_PLATFORM}/
if [ -e $PER_PLATFORM_IMAGE_EXTRAS ]; then
    rsync -pr $PER_PLATFORM_IMAGE_EXTRAS $IMGTEMPDIR/
fi

if [ ! -e ${IMGBUILDERDIR} ]; then
    pushd ${BUILD}
    wget --continue ${IMGBUILDERURL}
    #tar jvxf OpenWrt-ImageBuilder*.tar.bz2
    tar jxvf $IMGFILE
    popd
fi

pushd ${IMGBUILDERDIR}

make image PROFILE=${TARGET_PLATFORM} PACKAGES="${PREINSTALLED_PACKAGES}" FILES=${IMGTEMPDIR}

pushd bin/${ARCH}/
ln -s ../../packages .
popd

popd
