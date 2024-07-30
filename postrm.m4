#!/bin/sh
test "$1" = "remove" || exit 0
dir=/usr/local/lib/gcc/DETAILED_ARCH/VERSION/include-fixed
set -ex
test -d "$dir" && rm -r "$dir"
cd /usr/local/
rmdir -p lib/gcc/DETAILED_ARCH/VERSION
