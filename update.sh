#!/bin/bash
cd /var/mobile/zqzb

# 1. 生成索引文件（确保删除旧文件）
rm -f Packages Packages.*
dpkg-scanpackages -m . /dev/null > Packages

# 2. 生成压缩文件（同时保留xz和gz格式）
xz -c9 Packages > Packages.xz
gzip -c9 Packages > Packages.gz

# 3. 计算校验值（修正变量名）
md5_pkg=$(md5sum Packages | awk '{print $1}')
size_pkg=$(stat -c%s Packages)
md5_xz=$(md5sum Packages.xz | awk '{print $1}')
size_xz=$(stat -c%s Packages.xz)
md5_gz=$(md5sum Packages.gz | awk '{print $1}')
size_gz=$(stat -c%s Packages.gz)

# 4. 更新Release文件（完整重写更可靠）
{
  echo "Origin: iOS-GM Repo"
  echo "Label: iOS-GM"
  echo "Suite: stable"
  echo "Version: 1.0"
  echo "Architectures: iphoneos-arm iphoneos-arm64"
  echo "Components: main"
  echo "Description: iOS越狱软件源"
  echo "MD5Sum:"
  echo " $md5_pkg $size_pkg Packages"
  echo " $md5_xz $size_xz Packages.xz"
  echo " $md5_gz $size_gz Packages.gz"
  echo "SHA256:"
  sha256sum Packages Packages.xz Packages.gz | awk '{print " " $1 " " $2 " " $3}'
} > Release

# 5. 提交更新（添加错误检查）
if git add . && \
   git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M')" && \
   git push origin main
then
    echo "✅ 更新成功"
else
    echo "❌ 更新失败，请检查git状态"
    exit 1
fi