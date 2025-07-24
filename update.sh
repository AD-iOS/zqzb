#!/bin/bash
cd /var/mobile/zqzb

# 生成索引
dpkg-scanpackages -m debs /dev/null > Packages
gzip -c9 Packages > Packages.gz

# 计算校验值
md5_pkg=$(md5sum Packages | cut -d' ' -f1)
size_pkg=$(wc -c < Packages)
md5_gz=$(md5sum Packages.gz | cut -d' ' -f1)
size_gz=$(wc -c < Packages.gz)

# 更新Release文件
awk -v md5_pkg="$md5_pkg" -v size_pkg="$size_pkg" \
    -v md5_gz="$md5_gz" -v size_gz="$size_gz" '
BEGIN {print_flag=0}
/MD5Sum:/ {print; print_flag=1; next}
print_flag==1 && /Packages$/ { 
    print " " md5_pkg " " size_pkg " Packages"
    next
}
print_flag==1 && /Packages.gz$/ { 
    print " " md5_gz " " size_gz " Packages.gz"
    print_flag=0
    next
}
{print}
' Release > Release.new && mv Release.new Release

# 提交更新
git add .
git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M')"
git push origin main
