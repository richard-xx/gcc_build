#!/bin/bash
set -ex

# 移除其他目录
dir=PREFIX/lib/gcc/DETAILED_ARCH/VERSION/include-fixed
test -d \"\$dir\" && rm -r \"\$dir\"
cd PREFIX/ || exit
rmdir -p lib/gcc/DETAILED_ARCH/VERSION || true
