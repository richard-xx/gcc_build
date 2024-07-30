#!/bin/bash

set -e
export DEBIAN_FRONTEND=noninteractive

# Function to display usage information
usage() {
    echo "Usage: \$0 <GCC_VERSION_MAJOR>.<GCC_VERSION_MINOR>.<GCC_VERSION_PATCH>"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 1 ]; then
    usage
fi


# Variables
GCC_VERSION="$1"
GCC_VERSION_MAJOR=$(echo $GCC_VERSION | cut -d. -f1)
GCC_VERSION_MINOR=$(echo $GCC_VERSION | cut -d. -f2)
GCC_VERSION_PATCH=$(echo $GCC_VERSION | cut -d. -f3)


NUM_CORES=$(nproc)
PKGNAME=gcc-${GCC_VERSION}
INSTALL_DIR=/tmp/${PKGNAME}

mkdir -p -m 0755 ${INSTALL_DIR}/DEBIAN

# 获取系统架构
ARCH="$(dpkg --print-architecture)"
extraConfigureArgs=''
# 转换架构名称
case "$ARCH" in
    amd64)
        # DETAILED_ARCH="x86_64-pc-linux-gnu"
        ;;
    i386|i686)
        ARCH="i386"
        extraConfigureArgs="$extraConfigureArgs --with-arch-32=i686"
        ;;
    arm64)
        DETAILED_ARCH="aarch64-unknown-linux-gnu"
        ;;
    armel)
        extraConfigureArgs="$extraConfigureArgs --with-arch=armv5te --with-float=soft"
        ;;
    armhf)
        extraConfigureArgs="$extraConfigureArgs --with-arch=armv7-a+fp --with-float=hard --with-mode=thumb"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        # exit 1
        ;;
esac

cp -a /etc/apt/sources.list /etc/apt/sources.list.bak
sed -i "s@http://.*ubuntu.com@http://mirrors.cernet.edu.cn@g" /etc/apt/sources.list

# Install necessary packages
apt-get update
apt-get install -y build-essential wget tar xz-utils flex bison g++-multilib
# libgmp-dev libmpfr-dev libmpc-dev

# 获取详细的系统架构信息
# DETAILED_ARCH=$(gcc -dumpmachine 2>/dev/null)
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
gen_deb()
{
  m4 -P -DVERSION=${GCC_VERSION} -DARCH=${ARCH} -DMAJOR=${GCC_VERSION_MAJOR} /workspace/control.m4 > ${INSTALL_DIR}/DEBIAN/control
  m4 -P -DVERSION=${GCC_VERSION} -DDETAILED_ARCH=${gnuArch} /workspace/postinst.m4 > ${INSTALL_DIR}/DEBIAN/postinst
  m4 -P -DVERSION=${GCC_VERSION} -DDETAILED_ARCH=${gnuArch} /workspace/preinst.m4 > ${INSTALL_DIR}/DEBIAN/preinst
  chmod 0755 ${INSTALL_DIR}/DEBIAN/postinst ${INSTALL_DIR}/DEBIAN/preinst
  echo "Built $PKGNAME.deb"
}

gen_deb

# Download and extract GCC source code
wget -nv "https://mirrors.cernet.edu.cn/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz"
tar -xzf "gcc-$GCC_VERSION.tar.gz"
cd "gcc-$GCC_VERSION"

# Download prerequisites
./contrib/download_prerequisites

# Create a build directory
mkdir build
cd build

# Configure the build
# --prefix=/usr/local/gcc-$GCC_VERSION_MAJOR
../configure --disable-multilib \
  --enable-languages=c,c++ \
  --program-suffix="-${GCC_VERSION_MAJOR}" \
  --build="$gnuArch" \
  --enable-host-pie \
  --enable-host-shared \
  --enable-threads=posix \
  --disable-static \
  --enable-checking=release \
  --enable-multiarch \
  --disable-bootstrap \
  --enable-version-specific-runtime-libs \
  $extraConfigureArgs


# Compile GCC
make -j 4

# Install GCC to a temporary directory for packaging
make DESTDIR=$INSTALL_DIR install-strip

cd /tmp && dpkg-deb --build ${PKGNAME} ${PKGNAME}-${ARCH}.deb

cp ${PKGNAME} ${PKGNAME}-${ARCH}.deb /workspace/

# Create a tar.gz package
echo "Create a tar.xz package"
tar -cJf ${PKGNAME}-${ARCH}.tar.xz -C $INSTALL_DIR/usr/local .

cp ${PKGNAME}-${ARCH}.tar.xz /workspace/

# Cleanup
# cd ..
# rm -rf "gcc-$GCC_VERSION" "gcc-$GCC_VERSION.tar.gz" "$INSTALL_DIR"

echo "GCC $GCC_VERSION has been compiled and packaged as ${PKGNAME}-${ARCH}.tar.xz"

