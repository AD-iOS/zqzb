#!/bin/bash
REPO_URL="/var/mobile/zqzb/ad"
SUITE="ad"  # 改为 ad 与 Release 文件一致
COMPONENT="main"

# 创建完整的标准目录结构
mkdir -p dists/${SUITE}/${COMPONENT}/binary-iphoneos-arm
mkdir -p dists/${SUITE}/${COMPONENT}/binary-iphoneos-arm64
mkdir -p pool/${COMPONENT}

# 生成 Packages 文件（两个架构都需要）
dpkg-scanpackages -m pool/${COMPONENT} > dists/${SUITE}/${COMPONENT}/binary-iphoneos-arm/Packages
dpkg-scanpackages -m pool/${COMPONENT} > dists/${SUITE}/${COMPONENT}/binary-iphoneos-arm64/Packages

# 压缩 Packages 文件
gzip -k -f dists/${SUITE}/${COMPONENT}/binary-iphoneos-arm/Packages
gzip -k -f dists/${SUITE}/${COMPONENT}/binary-iphoneos-arm64/Packages

# 生成正确的 Release 文件
cd dists/${SUITE}
cat > Release << EOF
Origin: iOS-AD Repo
Label: iOS-AD Repo
Suite: ad
Codename: ad
Version: 1.0
Architectures: iphoneos-arm iphoneos-arm64
Components: main
Description: iOS-AD Repo — 提供越狱插件、自制工具及精选第三方插件
MD5Sum:
 $(md5sum main/binary-iphoneos-arm/Packages | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm/Packages) main/binary-iphoneos-arm/Packages
 $(md5sum main/binary-iphoneos-arm/Packages.gz | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm/Packages.gz) main/binary-iphoneos-arm/Packages.gz
 $(md5sum main/binary-iphoneos-arm64/Packages | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm64/Packages) main/binary-iphoneos-arm64/Packages
 $(md5sum main/binary-iphoneos-arm64/Packages.gz | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm64/Packages.gz) main/binary-iphoneos-arm64/Packages.gz
SHA256:
 $(sha256sum main/binary-iphoneos-arm/Packages | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm/Packages) main/binary-iphoneos-arm/Packages
 $(sha256sum main/binary-iphoneos-arm/Packages.gz | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm/Packages.gz) main/binary-iphoneos-arm/Packages.gz
 $(sha256sum main/binary-iphoneos-arm64/Packages | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm64/Packages) main/binary-iphoneos-arm64/Packages
 $(sha256sum main/binary-iphoneos-arm64/Packages.gz | cut -d' ' -f1) $(stat -f%z main/binary-iphoneos-arm64/Packages.gz) main/binary-iphoneos-arm64/Packages.gz
EOF