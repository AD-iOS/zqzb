#!/bin/bash

# 推送更新 sileodepiction<包名>js.json 用
# 同時推送其他文件不更新新 deb

cd /var/mobile/zqzb/

# 設置顏色輸出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}開始更新配置文件...${NC}"

# 檢查是否有文件變更
if git diff --quiet && git diff --staged --quiet; then
    echo -e "${YELLOW}沒有檢測到文件變更${NC}"
    exit 0
fi

# 顯示變更的文件
echo -e "${YELLOW}檢測到以下文件變更：${NC}"
git status --short

# 先拉取遠程更新避免衝突
echo -e "${YELLOW}同步遠程更新...${NC}"
git pull origin main --rebase --autostash

# 提交更新（只提交配置文件的更新）
echo -e "${YELLOW}提交更新...${NC}"
git add .

# 檢查具體哪些文件被更新
UPDATED_FILES=$(git diff --name-only --cached)
echo -e "${YELLOW}更新的文件：${NC}"
echo "$UPDATED_FILES"

git commit -m "配置文件更新 $(date +'%Y-%m-%d %H:%M')

更新文件：
$UPDATED_FILES"

# 推送前再次同步確保最新
echo -e "${YELLOW}推送前最終同步...${NC}"
git pull origin main --rebase

echo -e "${YELLOW}推送到 GitHub...${NC}"
if git push origin main; then
    echo -e "${GREEN}配置文件更新成功！${NC}"
else
    echo -e "${RED}推送失敗，請手動處理${NC}"
    echo "運行: git push origin main"
fi