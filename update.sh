#!/bin/bash

# 智能倉庫更新腳本 - 避免與 GitHub Actions 衝突
# 功能：同時處理 SileoDepiction 更新和 DEB 包索引生成

cd /var/mobile/zqzb/

# 設置顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== 智能倉庫更新腳本開始 ===${NC}"

# 檢查 Git 狀態
echo -e "${YELLOW}檢查 Git 狀態...${NC}"
if ! git status &> /dev/null; then
    echo -e "${RED}錯誤：不是 Git 倉庫或 Git 未初始化${NC}"
    exit 1
fi

# 檢查並清理可能存在的衝突狀態
cleanup_git_state() {
    echo -e "${YELLOW}檢查 Git 狀態...${NC}"
    
    # 檢查是否有未完成的合併或 rebase
    if [ -f ".git/MERGE_HEAD" ]; then
        echo -e "${YELLOW}發現未完成的合併，取消合併...${NC}"
        git merge --abort
    fi
    
    if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
        echo -e "${YELLOW}發現未完成的 rebase，取消 rebase...${NC}"
        git rebase --abort
    fi
    
    # 檢查是否有未提交的更改
    if ! git diff --quiet && ! git diff --staged --quiet; then
        echo -e "${YELLOW}發現未提交的更改，暫存更改...${NC}"
        git add .
    fi
}

# 同步遠程更改（智能處理衝突）
sync_with_remote() {
    echo -e "${YELLOW}同步遠程更新...${NC}"
    
    # 先獲取最新更改
    git fetch origin main
    
    # 檢查是否有遠程更新
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/main)
    
    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo -e "${YELLOW}檢測到遠程更新，正在同步...${NC}"
        
        # 暫存本地更改（如果有）
        if ! git diff --quiet || ! git diff --staged --quiet; then
            echo -e "${YELLOW}暫存本地更改...${NC}"
            git stash push -m "自動暫存: $(date +'%Y-%m-%d %H:%M:%S')"
            STASHED=true
        fi
        
        # 拉取遠程更新
        if git pull origin main --no-rebase; then
            echo -e "${GREEN}遠程同步成功${NC}"
        else
            echo -e "${RED}遠程同步失敗，嘗試強制重置...${NC}"
            git reset --hard origin/main
        fi
        
        # 恢復本地更改（如果有）
        if [ "$STASHED" = true ]; then
            echo -e "${YELLOW}恢復本地更改...${NC}"
            if git stash pop; then
                echo -e "${GREEN}本地更改恢復成功${NC}"
            else
                echo -e "${YELLOW}發現衝突，需要手動解決...${NC}"
                echo -e "${YELLOW}請手動解決衝突後運行: git add . && git commit${NC}"
                return 1
            fi
        fi
    else
        echo -e "${GREEN}本地已是最新版本${NC}"
    fi
    
    return 0
}

# 生成 DEB 包索引
generate_package_index() {
    echo -e "${YELLOW}檢查 DEB 包並生成索引...${NC}"
    
    # 檢查 debs 目錄
    if [ ! -d "debs" ]; then
        echo -e "${YELLOW}debs 目錄不存在，創建空目錄${NC}"
        mkdir -p debs
        touch debs/.keep
    fi
    
    # 檢查是否有 DEB 文件
    DEB_FILES=$(find debs -name "*.deb" | wc -l)
    if [ "$DEB_FILES" -eq 0 ]; then
        echo -e "${YELLOW}未找到 DEB 文件${NC}"
        return 0
    fi
    
    echo -e "${GREEN}找到 $DEB_FILES 個 DEB 文件${NC}"
    
    # 生成 Packages 文件
    echo -e "${YELLOW}生成 Packages 索引...${NC}"
    dpkg-scanpackages -m debs /dev/null > Packages 2>/dev/null
    
    # 生成壓縮包
    gzip -c9 Packages > Packages.gz
    bzip2 -c9 Packages > Packages.bz2
    
    # 更新 Release 文件
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
EOF

    echo "MD5Sum:" >> Release
    for file in Packages Packages.gz Packages.bz2; do
        if [ -f "$file" ]; then
            size=$(wc -c < "$file")
            md5=$(md5sum "$file" | cut -d' ' -f1)
            echo " $md5 $size $file" >> Release
        fi
    done
    
    echo -e "${GREEN}包索引生成完成${NC}"
    return 0
}

# 檢查 SileoDepiction 文件
check_depiction_files() {
    echo -e "${YELLOW}檢查 SileoDepiction 文件...${NC}"
    
    DEPICTION_FILES=$(find . -name "*sileodepiction*json" | wc -l)
    if [ "$DEPICTION_FILES" -eq 0 ]; then
        echo -e "${YELLOW}未找到 SileoDepiction 文件${NC}"
    else
        echo -e "${GREEN}找到 $DEPICTION_FILES 個 SileoDepiction 文件${NC}"
    fi
}

# 主執行流程
main() {
    # 步驟 1: 清理 Git 狀態
    cleanup_git_state
    
    # 步驟 2: 同步遠程更新
    if ! sync_with_remote; then
        echo -e "${RED}同步失敗，請手動解決衝突後重新運行腳本${NC}"
        exit 1
    fi
    
    # 步驟 3: 生成包索引
    generate_package_index
    
    # 步驟 4: 檢查描述文件
    check_depiction_files
    
    # 步驟 5: 檢查是否有更改需要提交
    echo -e "${YELLOW}檢查文件變更...${NC}"
    if git diff --quiet && git diff --staged --quiet; then
        echo -e "${YELLOW}沒有檢測到文件變更${NC}"
        echo -e "${BLUE}=== 腳本執行完成 ===${NC}"
        exit 0
    fi
    
    # 顯示變更的文件
    echo -e "${YELLOW}檢測到以下文件變更：${NC}"
    git status --short
    
    # 步驟 6: 提交更改
    echo -e "${YELLOW}提交更新...${NC}"
    git add .
    
    CHANGED_FILES=$(git diff --name-only --cached)
    DEB_COUNT=$(find debs -name "*.deb" 2>/dev/null | wc -l)
    
    git commit -m "智能更新 $(date +'%Y-%m-%d %H:%M')

更新內容:
- DEB 包數量: $DEB_COUNT
- 變更文件: $(echo "$CHANGED_FILES" | head -5 | tr '\n' ' ')$([ $(echo "$CHANGED_FILES" | wc -l) -gt 5 ] && echo " ...")"
    
    # 步驟 7: 最終同步並推送
    echo -e "${YELLOW}最終同步...${NC}"
    git fetch origin main
    
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
        echo -e "${YELLOW}檢測到新的遠程更新，重新同步...${NC}"
        if git pull origin main --rebase; then
            echo -e "${GREEN}重新同步成功${NC}"
        else
            echo -e "${RED}重新同步失敗，請手動解決${NC}"
            exit 1
        fi
    fi
    
    # 步驟 8: 推送更改
    echo -e "${YELLOW}推送到倉庫...${NC}"
    if git push origin main; then
        echo -e "${GREEN}推送成功！${NC}"
        echo -e "${BLUE}=== 更新完成 ===${NC}"
    else
        echo -e "${RED}推送失敗${NC}"
        echo -e "${YELLOW}請手動運行: git push origin main${NC}"
    fi
}

# 執行主函數
main