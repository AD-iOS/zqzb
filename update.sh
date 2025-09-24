#!/bin/bash

cd /var/mobile/zqzb

# 1. 創建目錄結構
mkdir -p pool/main/c
mkdir -p dists/AD/main/binary-iphoneos-{arm64,all}

# 2. 生成索引文件
echo "生成索引文件..."

# arm64 架構
dpkg-scanpackages --arch arm64 pool/ > dists/AD/main/binary-iphoneos-arm64/Packages
gzip -kf dists/AD/main/binary-iphoneos-arm64/Packages
xz -kf dists/AD/main/binary-iphoneos-arm64/Packages 2>/dev/null || echo "xz 不可用，跳過"

# all 架構
dpkg-scanpackages --arch all pool/ > dists/AD/main/binary-iphoneos-all/Packages
gzip -kf dists/AD/main/binary-iphoneos-all/Packages
xz -kf dists/AD/main/binary-iphoneos-all/Packages 2>/dev/null || echo "xz 不可用，跳過"

# 3. 生成 Release 文件
cd dists/AD
cat > Release << EOF
Origin: iOS-AD Repo
Label: iOS-AD Repo
Suite: AD
Codename: AD
Architectures: iphoneos-arm64 iphoneos-all
Components: main
Description: iOS-AD Repo — 提供越狱插件、自制工具及精选第三方插件
Date: $(date -u +'%a, %d %b %Y %H:%M:%S %Z')
EOF

apt-ftparchive release . >> Release
cd ../..

# 4. 提交更新
git add .
git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M:%S')"
git pull --rebase
git push origin main

echo "軟件源更新完成！"