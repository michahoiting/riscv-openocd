#!/bin/bash

# Script to cross build the 32-bit Windows version of OpenOCD with MinGW-w64
# on Debian.

# Prerequisites:
#
# sudo apt-get install git doxygen libtool autoconf automake texinfo texlive \
# autotools-dev pkg-config  mingw-w64 mingw-w64-tools mingw-w64-dev

# DEBUG="y"

WORK="/media/Work/openocd"
mkdir -p "${WORK}"

OUTFILE_VERSION="0.8.0"
OPENOCD_TARGET="w32"

INPUT_VERSION="0.8.0"
INPUT_ZIP="openocd-${INPUT_VERSION}_x86_devkit.zip"
INPUT_ZIP_FOLDER="openocd-${INPUT_VERSION}_x86_devkit"

OPENOCD_GIT_FOLDER="${WORK}/gnuarmeclipse-openocd.git"
OPENOCD_DOWNLOAD_FOLDER="${WORK}/download"
OPENOCD_BUILD_FOLDER="${WORK}/build/${OPENOCD_TARGET}"
OPENOCD_INSTALL_FOLDER="${WORK}/install/${OPENOCD_TARGET}"

if [ ! -d "${OPENOCD_INSTALL_FOLDER}/${INPUT_ZIP_FOLDER}" ]
then
    mkdir -p "${OPENOCD_DOWNLOAD_FOLDER}"
    cd "${OPENOCD_DOWNLOAD_FOLDER}"
    wget "http://sourceforge.net/projects/picusb/files/${INPUT_ZIP}"

    mkdir -p "${OPENOCD_INSTALL_FOLDER}"
    cd "${OPENOCD_INSTALL_FOLDER}"
    unzip "${OPENOCD_DOWNLOAD_FOLDER}/${INPUT_ZIP}"
fi

if [ ! -d "${OPENOCD_GIT_FOLDER}" ]
then
    cd "${WORK}"

    if [ "$(whoami)" == "ilg" ]
    then
        git clone ssh://ilg-ul@git.code.sf.net/p/gnuarmeclipse/openocd gnuarmeclipse-openocd.git
    else
        git clone http://git.code.sf.net/p/gnuarmeclipse/openocd gnuarmeclipse-openocd.git
    fi

    # Change to the gnuarmeclipse branch.
    cd "${OPENOCD_GIT_FOLDER}"
    git checkout gnuarmeclipse

    # Prepare autotools.
    cd "${OPENOCD_GIT_FOLDER}"
    ./bootstrap
fi


export CROSS_COMPILE="i686-w64-mingw32"

export OUTPUT_DIR="${OPENOCD_BUILD_FOLDER}"
export PKG_CONFIG_PREFIX="${OPENOCD_INSTALL_FOLDER}/${INPUT_ZIP_FOLDER}/dev_kit"

export LIBFTDI_CFLAGS="-I${PKG_CONFIG_PREFIX}/include/libftdi1"
export LIBUSB1_CFLAGS="-I${PKG_CONFIG_PREFIX}/include/libusb-1.0"
export LIBUSB0_CFLAGS="-I${PKG_CONFIG_PREFIX}/include/libusb-win32"

export LIBFTDI_LIBS="-L${PKG_CONFIG_PREFIX}/lib -lftdi1"
export LIBUSB1_LIBS="-L${PKG_CONFIG_PREFIX}/lib -lusb-1.0"
export LIBUSB0_LIBS="-L${PKG_CONFIG_PREFIX}/lib -lusb"
export HIDAPI_CFLAGS="-I${PKG_CONFIG_PREFIX}/include/hidapi"
export HIDAPI_LIBS="-L${PKG_CONFIG_PREFIX}/lib -lhidapi"

export PKG_CONFIG_PATH="${PKG_CONFIG_PREFIX}/lib/pkgconfig"

if [ "${DEBUG}" == "y" ]
then
    export CFLAGS="-g"
fi

mkdir -p "${OPENOCD_BUILD_FOLDER}"

if [ -f "${OPENOCD_BUILD_FOLDER}/config.h" ]
then
    cd "${OPENOCD_BUILD_FOLDER}"
    make distclean
fi

mkdir -p "${OPENOCD_BUILD_FOLDER}"
cd "${OPENOCD_BUILD_FOLDER}"
"${OPENOCD_GIT_FOLDER}/configure" \
--build=$(uname -m)-linux-gnu \
--host=$CROSS_COMPILE \
--prefix=""  \
--enable-aice \
--enable-amtjtagaccel \
--enable-armjtagew \
--enable-cmsis-dap \
--enable-ftdi \
--enable-gw16012 \
--enable-jlink \
--enable-jtag_vpi \
--enable-opendous \
--enable-openjtag_ftdi \
--enable-osbdm \
--enable-legacy-ft2232_libftdi \
--enable-parport \
--disable-parport-ppdev \
--enable-parport-giveio \
--enable-presto_libftdi \
--enable-remote-bitbang \
--enable-rlink \
--enable-stlink \
--enable-ti-icdi \
--enable-ulink \
--enable-usb-blaster-2 \
--enable-usb_blaster_libftdi \
--enable-usbprog \
--enable-vsllink

make bindir="bin" pkgdatadir= all pdf html
if [ "${DEBUG}" != "y" ]
then
  ${CROSS_COMPILE}-strip src/openocd.exe
fi

mkdir -p "${WORK}/output"

NSIS_FOLDER="${OPENOCD_GIT_FOLDER}/nsis"
NSIS_FILE="${NSIS_FOLDER}/gnuarmeclipse-openocd.nsi"

NDATE=$(date -u +%Y%m%d%H%M)
OUTFILE="${WORK}/output/gnuarmeclipse-openocd-w32-${OUTFILE_VERSION}-${NDATE}-setup.exe"

NSIS_FLAGS="-V4 -NOCD"

cd "${OPENOCD_BUILD_FOLDER}"
makensis ${NSIS_FLAGS} \
-DGIT_FOLDER="${OPENOCD_GIT_FOLDER}" \
-DBUILD_FOLDER="${OPENOCD_BUILD_FOLDER}" \
-DINSTALL_FOLDER="${OPENOCD_INSTALL_FOLDER}/${INPUT_ZIP_FOLDER}" \
-DNSIS_FOLDER="${NSIS_FOLDER}" \
-DOUTFILE="${OUTFILE}" \
"${NSIS_FILE}"