#!/bin/bash

cd /var/mobile/zqzb/

# 設置顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}開始更新 Cydia 倉庫...${NC}"

# 檢查是否處於 rebase 狀態
if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
    echo -e "${RED}檢測到未完成的 rebase 操作${NC}"
    echo -e "${YELLOW}正在取消 rebase...${NC}"
    git rebase --abort
fi

# 生成索引文件
echo -e "${YELLOW}生成 Packages 文件...${NC}"
dpkg-scanpackages -m . /dev/null > Packages
gzip -c Packages > Packages.gz

# 提交更新
echo -e "${YELLOW}提交更新...${NC}"
git add .

# 檢查是否有更改需要提交
if git diff --staged --quiet; then
    echo -e "${YELLOW}沒有檢測到更改${NC}"
    exit 0
fi

git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M')"

# 同步遠程更改（使用 merge 而不是 rebase 避免衝突）
echo -e "${YELLOW}同步遠程更新...${NC}"
if ! git pull origin main --no-rebase; then
    echo -e "${RED}同步失敗，嘗試解決衝突...${NC}"
    # 如果 pull 失敗，先 stash 當前更改
    git stash
    git pull origin main
    git stash pop
    # 如果有衝突，需要手動解決
    if git status | grep -q "both modified"; then
        echo -e "${RED}發現衝突，請手動解決：${NC}"
        git status
        exit 1
    fi
fi

# 推送更新
echo -e "${YELLOW}推送到 GitHub...${NC}"
if git push origin main; then
    echo -e "${GREEN}更新成功！${NC}"
else
    echo -e "${RED}推送失敗${NC}"
    echo "請手動運行: git push origin main"
fi