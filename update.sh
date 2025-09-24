#!/bin/bash

cd /var/mobile/zqzb

# 1. 創建目錄結構（如果不存在）
mkdir -p pool/main/c
mkdir -p dists/AD/main/iphoneos-{arm64,all}

# 2. 為每個架構生成索引
echo "生成索引文件..."

# 為 arm64 架構生成索引
dpkg-scanpackages --arch arm64 pool/ > dists/AD/main/iphoneos-arm64/Packages
gzip -kf dists/AD/main/iphoneos-arm64/Packages  # 改用 -kf 參數

# 為 all 架構生成索引
dpkg-scanpackages --arch all pool/ > dists/AD/main/iphoneos-all/Packages
gzip -kf dists/AD/main/iphoneos-all/Packages    # 改用 -kf 參數

# 3. 創建兼容性鏈接（解決客戶端bug）
# cd dists/AD/main/
# 為錯誤的架構名稱創建符號鏈接
# ln -sf iphoneos-arm64 binary-iphoneos-arm64 2>/dev/null || true
# ln -sf iphoneos-arm64 binary-iphoneos-arm64 2>/dev/null || true
cd /var/mobile/zqzb

# 4. 生成 Release 文件
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

# 5. 提交更新
echo "提交更新..."
git add .
git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M:%S')"
git pull --rebase
git push origin main

echo "軟件源更新完成！"