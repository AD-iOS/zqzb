#!/bin/bash
cd /var/mobile/zqzb

# 1. 清理旧文件
rm -f Packages Packages.*

# 2. 生成原始索引文件
dpkg-scanpackages -m . /dev/null > Packages

# 3. 生成所有压缩格式
gzip -c9 Packages > Packages.gz
xz -c9 Packages > Packages.xz
bzip2 -c9 Packages > Packages.bz2
zstd -c19 Packages > Packages.zst

# 4. 计算所有校验值
{
  echo "Origin: iOS-GM Repo"
  echo "Label: iOS-GM"
  echo "Suite: stable"
  echo "Version: 1.0"
  echo "Architectures: iphoneos-arm iphoneos-arm64"
  echo "Components: main"
  echo "Description: iOS越狱软件源"
  
  # MD5Sum 区块
  echo "MD5Sum:"
  for file in Packages Packages.{gz,xz,bz2,zst}; do
    [ -f "$file" ] && echo " $(md5sum "$file" | awk '{print $1, $2}')"
  done
  
  # SHA256 区块
  echo "SHA256:"
  for file in Packages Packages.{gz,xz,bz2,zst}; do
    [ -f "$file" ] && echo " $(sha256sum "$file" | awk '{print $1, $2}')"
  done
} > Release

# 5. 提交更新
git add .
git commit -m "更新索引文件（全格式支持）"
git push origin main