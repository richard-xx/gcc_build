#!/bin/bash

set -e

# Function to display usage information
usage() {
    echo "Usage: \$0 <GCC_VERSION_MAJOR> <GCC_VERSION_MINOR> <GCC_VERSION_PATCH>"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 3 ]; then
    usage
fi

# Variables
GCC_VERSION_MAJOR=$1
GCC_VERSION_MINOR=$2
GCC_VERSION_PATCH=$3
GCC_VERSION="${GCC_VERSION_MAJOR}.${GCC_VERSION_MINOR}.${GCC_VERSION_PATCH}"

NUM_CORES=$(nproc)
INSTALL_DIR=$(pwd)/gcc-install

# Install necessary packages
apt-get update
apt-get install -y build-essential checkinstall wget tar xz-utils
# libgmp-dev libmpfr-dev libmpc-dev
# Download and extract GCC source code
wget "https://ftpmirror.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz"
tar -xzf "gcc-$GCC_VERSION.tar.gz"
cd "gcc-$GCC_VERSION"

# Download prerequisites
./contrib/download_prerequisites

# Create a build directory
mkdir build
cd build

# Configure the build
# --prefix=/usr/local/gcc-$GCC_VERSION_MAJOR
../configure --disable-multilib --enable-languages=c,c++ \
  --program-suffix="-${GCC_VERSION_MAJOR}" \
  --enable-host-pie \
  --enable-host-shared \
  --enable-threads=posix

# Compile GCC
make -j$NUM_CORES

# Install GCC using checkinstall and create a .deb package
checkinstall --pkgname=gcc --pkgversion=$GCC_VERSION --backup=no --deldoc=yes --deldesc=yes --delspec=yes --default make install

# Install GCC to a temporary directory for packaging
make DESTDIR=$INSTALL_DIR install-strip

# Create a tar.gz package
cd $INSTALL_DIR
echo "Create a tar.xz package"
tar -cJf ../gcc-$GCC_VERSION.tar.xz *

# Cleanup
cd ..
# rm -rf "gcc-$GCC_VERSION" "gcc-$GCC_VERSION.tar.gz" "$INSTALL_DIR"

echo "GCC $GCC_VERSION has been compiled and packaged as gcc-$GCC_VERSION.tar.gz"

