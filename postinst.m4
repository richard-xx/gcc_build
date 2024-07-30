#!/bin/sh
# postinst.m4

# 检查是否是在 configure 阶段
test "$1" = "configure" || exit 0

# 启用调试输出
set -x

# 执行特定的工具
/usr/local/libexec/gcc/DETAILED_ARCH/VERSION/install-tools/mkheaders

# 创建 ld.so.conf.d 配置文件
{ echo '/usr/local/lib64'; echo '/usr/local/lib'; } > /etc/ld.so.conf.d/000-local-lib.conf

# 更新动态链接库缓存
ldconfig -v

