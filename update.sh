#!/bin/bash

# 單向推送腳本 - 本地強制覆蓋遠程倉庫
# 功能：將本地新版強制推送到 GitHub，避免老版本覆蓋新版本

cd /var/mobile/zqzb/

# 設置顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== 單向推送腳本（本地 → GitHub）===${NC}"

# 檢查 Git 狀態
echo -e "${YELLOW}檢查 Git 狀態...${NC}"
if ! git status &> /dev/null; then
    echo -e "${RED}錯誤：不是 Git 倉庫或 Git 未初始化${NC}"
    exit 1
fi

# 清理 Git 狀態
cleanup_git_state() {
    echo -e "${YELLOW}清理 Git 狀態...${NC}"
    
    # 檢查並取消未完成的合併
    if [ -f ".git/MERGE_HEAD" ]; then
        echo -e "${YELLOW}取消未完成的合併...${NC}"
        git merge --abort
    fi
    
    # 檢查並取消未完成的 rebase
    if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
        echo -e "${YELLOW}取消未完成的 rebase...${NC}"
        git rebase --abort
    fi
    
    # 重置所有未提交的更改（可選，根據需要開啟）
    # if ! git diff --quiet || ! git diff --staged --quiet; then
    #     echo -e "${YELLOW}發現未提交的更改，已保留${NC}"
    # fi
}

# 生成 DEB 包索引
generate_package_index() {
    echo -e "${YELLOW}生成 DEB 包索引...${NC}"
    
    # 確保 debs 目錄存在
    if [ ! -d "debs" ]; then
        echo -e "${YELLOW}創建 debs 目錄...${NC}"
        mkdir -p debs
        touch debs/.keep
    fi
    
    # 檢查 DEB 文件數量
    DEB_COUNT=$(find debs -name "*.deb" 2>/dev/null | wc -l)
    echo -e "${GREEN}找到 $DEB_COUNT 個 DEB 文件${NC}"
    
    if [ "$DEB_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}找到以下 DEB 文件：${NC}"
        find debs -name "*.deb" -exec echo "  - {}" \;
    fi
    
    # 生成 Packages 文件
    echo -e "${YELLOW}生成 Packages 索引...${NC}"
    if [ "$DEB_COUNT" -gt 0 ]; then
        dpkg-scanpackages -m debs /dev/null > Packages 2>/dev/null
    else
        echo "# 空 Packages 文件 - 沒有可用的 deb 包" > Packages
    fi
    
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
}

# 檢查 SileoDepiction 文件
check_depiction_files() {
    echo -e "${YELLOW}檢查 SileoDepiction 文件...${NC}"
    
    DEPICTION_FILES=$(find . -name "*sileodepiction*json" 2>/dev/null | wc -l)
    if [ "$DEPICTION_FILES" -eq 0 ]; then
        echo -e "${YELLOW}未找到 SileoDepiction 文件${NC}"
    else
        echo -e "${GREEN}找到 $DEPICTION_FILES 個 SileoDepiction 文件${NC}"
        find . -name "*sileodepiction*json" -exec echo "  - {}" \; 2>/dev/null
    fi
}

# 強制推送本地到遠程
force_push_to_remote() {
    echo -e "${YELLOW}準備強制推送...${NC}"
    
    # 顯示本地和遠程的差異
    echo -e "${YELLOW}檢查本地與遠程的差異...${NC}"
    git fetch origin main
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/main)
    
    if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
        echo -e "${GREEN}本地與遠程版本一致${NC}"
    else
        echo -e "${YELLOW}本地與遠程版本不一致：${NC}"
        echo -e "  本地提交: $LOCAL_COMMIT"
        echo -e "  遠程提交: $REMOTE_COMMIT"
        echo -e "${YELLOW}將用本地版本覆蓋遠程版本${NC}"
    fi
    
    # 顯示將要推送的更改
    echo -e "${YELLOW}將要推送的更改：${NC}"
    git status --short
    
    # 確認推送（可選，如果需要確認可以取消註釋）
    # read -p "是否繼續強制推送？(y/N): " -n 1 -r
    # echo
    # if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    #     echo -e "${YELLOW}已取消推送${NC}"
    #     exit 0
    # fi
    
    # 強制推送
    echo -e "${YELLOW}執行強制推送...${NC}"
    if git push origin main --force; then
        echo -e "${GREEN}強制推送成功！${NC}"
        echo -e "${GREEN}本地新版已覆蓋遠程老版本${NC}"
    else
        echo -e "${RED}強制推送失敗！${NC}"
        echo -e "${YELLOW}請檢查網絡連接和權限設置${NC}"
        exit 1
    fi
}

# 主執行流程
main() {
    # 步驟 1: 清理 Git 狀態
    cleanup_git_state
    
    # 步驟 2: 生成包索引
    generate_package_index
    
    # 步驟 3: 檢查描述文件
    check_depiction_files
    
    # 步驟 4: 添加所有更改
    echo -e "${YELLOW}添加文件更改...${NC}"
    git add -A
    
    # 步驟 5: 檢查是否有更改需要提交
    if git diff --staged --quiet; then
        echo -e "${YELLOW}沒有檢測到文件變更${NC}"
    else
        # 顯示變更統計
        DEB_COUNT=$(find debs -name "*.deb" 2>/dev/null | wc -l)
        DEPICTION_COUNT=$(find . -name "*sileodepiction*json" 2>/dev/null | wc -l)
        CHANGED_FILES=$(git diff --name-only --cached | tr '\n' ' ' | head -c 100)
        
        echo -e "${YELLOW}提交本地更改...${NC}"
        git commit -m "本地強制更新 $(date +'%Y-%m-%d %H:%M')

更新內容:
- DEB 包數量: $DEB_COUNT
- SileoDepiction 文件: $DEPICTION_COUNT
- 主要變更: $CHANGED_FILES"
        
        echo -e "${GREEN}本地提交完成${NC}"
    fi
    
    # 步驟 6: 強制推送到 GitHub
    force_push_to_remote
    
    echo -e "${BLUE}=== 單向推送完成 ===${NC}"
    echo -e "${GREEN}本地新版內容已成功推送到 GitHub 倉庫${NC}"
}

# 執行主函數
main