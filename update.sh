#!/bin/bash

cd /var/mobile/zqzb

# 1. 創建目錄結構（如果不存在）
mkdir -p pool/main/c
mkdir -p dists/AD/main/iphoneos-{arm64,all}

# 2. 為每個架構生成索引
echo "生成索引文件..."

# 為 arm64 架構生成索引
dpkg-scanpackages --arch arm64 pool/ > dists/AD/main/iphoneos-arm64/Packages
gzip -c dists/AD/main/iphoneos-arm64/Packages > dists/AD/main/iphoneos-arm64/Packages.gz

# 為 all 架構生成索引
dpkg-scanpackages --arch all pool/ > dists/AD/main/iphoneos-all/Packages
gzip -c dists/AD/main/iphoneos-all/Packages > dists/AD/main/iphoneos-all/Packages.gz

# 3. 生成 Release 文件
cd dists/AD
cat > Release << EOF
Origin: iOS-AD Repo
Label: iOS-AD Repo
Suite: AD
Codename: AD
Version: 1.0
Maintainer: AD
Architectures: iphoneos-arm64 iphoneos-all
Components: main
Description: iOS-AD Repo — 提供越狱插件、自制工具及精选第三方插件
Icon: https://ios-gm.github.io/zqzb/CydiaIcon.png
SileoIcon: https://ios-gm.github.io/zqzb/RepoIcon.png
Header: https://ios-gm.github.io/zqzb/sileodepiction/Default/top_0.png
Date: $(date -u +'%a, %d %b %Y %H:%M:%S %Z')
EOF

apt-ftparchive release . >> Release
cd ../..

# 4. 提交更新
echo "提交更新..."
git add .
git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M:%S')"
git pull --rebase
git push origin main

echo "軟件源更新完成！"