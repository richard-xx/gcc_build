#!/bin/bash
# preinst.m4

# 检查是否是在 configure 阶段
test "$1" = "configure" || exit 0

# 启用调试输出
set -x

# 获取当前时间，格式为 'YYYYMMDD_HHMMSS'
current_time=$(date +"%Y%m%d_%H%M%S")

# 定义要处理的目录和文件列表
declare -A directories_and_files=(
    ["/usr/local/lib64"]="libcc1.so libcc1.so.0 libcc1.so.0.0.0 libcc1.la"
    ["/usr/local/lib/gcc/DETAILED_ARCH/lib64"]="libgcc_s.so libgcc_s.so.1"
)

# 动态修改 postrm 脚本内容
postrm_content="#!/bin/bash
set -e
set -x

# 移除其他目录
dir=/usr/local/lib/gcc/DETAILED_ARCH/VERSION/include-fixed
test -d \"\$dir\" && rm -r \"\$dir\"
cd /usr/local/ || exit
rmdir -p lib/gcc/DETAILED_ARCH/VERSION || true
"

# 遍历每个目录
for target_dir in "${!directories_and_files[@]}"; do
    # 备份目录的路径
    backup_dir="${target_dir}/bak_$current_time"
    mkdir -p "$backup_dir"

    # 获取文件列表
    files_found=(${directories_and_files[$target_dir]})

    # 移动文件到备份目录
    for file in "${files_found[@]}"; do
        if [ -f "$target_dir/$file" ]; then
            mv "$target_dir/$file" "$backup_dir"
            echo "Moved $target_dir/$file to $backup_dir"
        else
            echo "File $target_dir/$file does not exist"
        fi
    done

    # 添加恢复代码到 postrm 脚本内容
    postrm_content+="
# 恢复 $target_dir 的备份文件
if [ -d \"$backup_dir\" ]; then
    mv \"$backup_dir\"/* \"$target_dir\"
    rmdir \"$backup_dir\"
    echo \"Restored files from $backup_dir to $target_dir\"
else
    echo \"Backup directory $backup_dir does not exist or is not a directory.\"
fi
"
done

# 动态生成 postrm 脚本
echo "$postrm_content" > /var/lib/dpkg/info/${DPKG_MAINTSCRIPT_PACKAGE}.postrm

# 设置 postrm 脚本的执行权限
chmod +x /var/lib/dpkg/info/${DPKG_MAINTSCRIPT_PACKAGE}.postrm

exit 0

