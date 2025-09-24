#!/bin/bash
REPO_ROOT="/var/mobile/zqzb/ad"
SUITE="stable"
COMPONENT="main"
ARCH="iphoneos-arm64"

# 创建标准目录结构
mkdir -p ${REPO_ROOT}/dists/${SUITE}/${COMPONENT}/binary-${ARCH}
mkdir -p ${REPO_ROOT}/pool/${COMPONENT}

# 生成 Packages 文件
dpkg-scanpackages -m ${REPO_ROOT}/pool/${COMPONENT} > ${REPO_ROOT}/dists/${SUITE}/${COMPONENT}/binary-${ARCH}/Packages
gzip -k -f ${REPO_ROOT}/dists/${SUITE}/${COMPONENT}/binary-${ARCH}/Packages

# 生成 dists/ 下的 Release 文件
cd ${REPO_ROOT}/dists/${SUITE}
apt-ftparchive release . > Release

# 关键：在根目录生成 Release 文件
cd ${REPO_ROOT}
cat > Release << EOF
Origin: iOS-AD Repo
Label: iOS-AD Repo
Suite: ${SUITE}
Codename: ${SUITE}
Version: 1.0
Architectures: ${ARCH}
Components: ${COMPONENT}
Description: iOS-AD Repo
Date: $(date -u +"%a, %d %b %Y %H:%M:%S %Z")
EOF

echo "\nyes"