#!/bin/bash

export LANG="C"

cd /var/mobile/zqzb

dpkg-scanpackages -m . /dev/null > Packages
xz -c Packages > Packages.xz
bzip2 -c Packages > Packages.bz2
gzip -c Packages > Packages.gz
zstd -c Packages > Packages.zst

#### pkg
md5_pkg=$(md5sum Packages | cut -d' ' -f1)
size_pkg=$(wc -c < Packages)
#### xz
md5_xz=$(md5sum Packages.xz | cut -d' ' -f1)
size_xz=$(wc -c < Packages.xz)
#### bz2
md5_bz2=$(md5sum Packages.bz2 | cut -d' ' -f1)
size_bz2=$(wc -c < Packages.bz2)
#### zst
md5_zst=$(md5sum Packages.zst | cut -d' ' -f1)
size_zst=$(wc -c < Packages.zst)

cat > Release << EOF
Origin: iOS-AD Repo
Label: iOS-AD Repo
Suite: AD
Codename: AD
Version: 1.0
Maintainer: AD
Architectures: iphoneos-arm64 iphoneos-arm64e iphoneos-all
Components: main
Description: iOS-AD Repo — 提供越狱插件、自制工具及精选第三方插件, 重新維護日期: 2026-2-8!
EOF

echo "Date: $(date -R)" >> Release
echo "MD5Sum:" >> Release

#### pkg
echo " $md5_pkg $size_pkg Packages" >> Release
#### xz
echo " $md5_xz $size_xz Packages.xz" >> Release
#### bz2
echo " $md5_bz2 $size_bz2 Packages.bz2" >> Release
#### gz
echo " $md5_gz $size_gz Packages.gz" >> Release
#### zst
echo " $md5_zst $size_zst Packages.zst" >> Release

# 提交更新
git add .
git commit -m "from update of AD $(date +'%Y-%m-%d %H:%M')"
git pull --rebase
git push origin main
