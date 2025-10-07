#!/bin/bash

# SSH 強制推送腳本 - 專門用於 SSH 方式推送
cd /var/mobile/zqzb/

# 設置顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== SSH 強制推送腳本 ===${NC}"

# 檢查 SSH 配置
echo -e "${YELLOW}檢查 SSH 配置...${NC}"
if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
    echo -e "${YELLOW}未找到 SSH 私鑰，確保已配置 SSH${NC}"
fi

# 檢查遠程 URL 是否為 SSH
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$REMOTE_URL" != *"git@"* ]]; then
    echo -e "${YELLOW}當前遠程 URL: $REMOTE_URL${NC}"
    echo -e "${YELLOW}建議使用 SSH URL (git@github.com:用戶名/倉庫名.git)${NC}"
fi

# 生成包索引文件
echo -e "${YELLOW}生成倉庫索引文件...${NC}"

# 確保目錄結構
mkdir -p debs
touch .nojekyll

# 生成 Packages 文件
DEB_COUNT=0
if [ -d "debs" ] && [ "$(ls -A debs/*.deb 2>/dev/null)" ]; then
    DEB_COUNT=$(find debs -name "*.deb" | wc -l)
    echo -e "${GREEN}找到 $DEB_COUNT 個 DEB 文件，生成 Packages...${NC}"
    dpkg-scanpackages -m debs /dev/null > Packages 2>/dev/null
else
    echo -e "${YELLOW}未找到 DEB 文件，創建空 Packages${NC}"
    echo "# iOS-AD 倉庫 - 等待上傳包" > Packages
fi

# 生成壓縮包
gzip -ck9 Packages > Packages.gz
bzip2 -ck9 Packages > Packages.bz2

# 生成 Release 文件
CURRENT_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S UTC")
cat > Release << EOF
Origin: iOS-AD Repo
Label: iOS-AD Repo
Suite: AD
Codename: AD
Version: 1.0
Maintainer: AD
Architectures: iphoneos-arm64 iphoneos-arm64e iphoneos-all
Components: main
Description: iOS-AD Repo — 提供越狱插件、自制工具及精选第三方插件
Date: $CURRENT_DATE
MD5Sum:
EOF

# 計算文件哈希
for file in Packages Packages.gz Packages.bz2; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file" | awk '{print $1}')
        md5=$(md5sum "$file" | awk '{print $1}')
        echo " $md5 $size $file" >> Release
    fi
done

echo -e "${GREEN}索引文件生成完成${NC}"

# 檢查 SileoDepiction 文件
DEPICTION_COUNT=$(find . -name "*sileodepiction*json" 2>/dev/null | wc -l)
echo -e "${YELLOW}找到 $DEPICTION_COUNT 個 SileoDepiction 文件${NC}"

# 顯示變更狀態
echo -e "${YELLOW}當前文件狀態:${NC}"
git status --short

# 添加所有文件
echo -e "${YELLOW}添加文件到 Git...${NC}"
git add -A

# 檢查是否有更改
if git diff --staged --quiet; then
    echo -e "${YELLOW}沒有檢測到文件變更${NC}"
    echo -e "${BLUE}=== 完成 ===${NC}"
    exit 0
fi

# 提交更改
echo -e "${YELLOW}提交更改...${NC}"
CHANGED_FILES=$(git diff --name-only --cached | tr '\n' ' ' | sed 's/ $//')
git commit -m "SSH推送更新: $(date +'%Y-%m-%d %H:%M')

📦 DEB 包: $DEB_COUNT 個
📋 SileoDepiction: $DEPICTION_COUNT 個
🔄 更新文件: ${CHANGED_FILES:0:50}..."

echo -e "${GREEN}本地提交完成${NC}"

# 強制推送到 GitHub
echo -e "${YELLOW}開始強制推送到 GitHub...${NC}"
echo -e "${YELLOW}這將用本地版本完全覆蓋遠程倉庫${NC}"

# 先獲取遠程狀態（但不合併）
echo -e "${YELLOW}檢查遠程狀態...${NC}"
git fetch origin

# 顯示版本差異
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main 2>/dev/null || echo "無遠程分支")

echo -e "本地提交: ${LOCAL_COMMIT:0:8}"
echo -e "遠程提交: ${REMOTE_COMMIT:0:8}"

if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    echo -e "${YELLOW}⚠️  本地與遠程版本不一致，將強制覆蓋${NC}"
fi

# 執行強制推送
echo -e "${YELLOW}執行強制推送...${NC}"
if git push origin main --force; then
    echo -e "${GREEN}✅ 推送成功！${NC}"
    echo -e "${GREEN}本地內容已成功覆蓋 GitHub 倉庫${NC}"
    
    # 顯示推送信息
    echo -e "${BLUE}推送摘要:${NC}"
    echo -e "  - DEB 包數量: $DEB_COUNT"
    echo -e "  - SileoDepiction 文件: $DEPICTION_COUNT"
    echo -e "  - 推送時間: $(date +'%Y-%m-%d %H:%M:%S')"
else
    echo -e "${RED}❌ 推送失敗！${NC}"
    echo -e "${YELLOW}可能的原因:${NC}"
    echo -e "  - SSH 密鑰未正確配置"
    echo -e "  - 網絡連接問題"
    echo -e "  - 倉庫權限不足"
    echo -e ""
    echo -e "${YELLOW}解決方案:${NC}"
    echo -e "  1. 檢查 SSH 配置: ssh -T git@github.com"
    echo -e "  2. 確認遠程 URL: git remote get-url origin"
    echo -e "  3. 手動推送: git push origin main --force"
    exit 1
fi

echo -e "${BLUE}=== SSH 推送完成 ===${NC}"