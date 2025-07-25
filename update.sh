#!/bin/bash

cd /var/mobile/zqzb

# 生成索引文件
dpkg-scanpackages -m . /dev/null > Packages
xz -c9 Packages > Packages.xz

# 计算校验值
md5_pkg=$(md5sum Packages | cut -d' ' -f1)
size_pkg=$(wc -c < Packages)
md5_xz=$(md5sum Packages.xz | cut -d' ' -f1)
size_xz=$(wc -c < Packages.xz)

# 更新Release文件
awk -v md5_pkg="$md5_pkg" \
    -v size_pkg="$size_pkg" \
    -v md5_xz="$md5_xz" \
    -v size_xz="$size_xz" '
BEGIN {print_flag=0}
/MD5Sum:/ {print; print_flag=1; next}
print_flag==1 && /Packages$/ { 
    print " " md5_pkg " " size_pkg " Packages"
    next
}
print_flag==1 && /Packages.xz$/ { 
    print " " md5_xz " " size_xz " Packages.xz"
    print_flag=0
    next
}
{print}
' Release > Release.new && mv Release.new Release

# 提交更新
git add .
git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M')"
git pull --rebase
git push origin main