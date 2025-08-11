#!/bin/bash

cd /var/mobile/zqzb

# 生成索引文件
dpkg-scanpackages -m . /dev/null > Packages
gzip -c Packages > Packages.gz

# 提交更新
git add .
git commit -m "Auto-update $(date +'%Y-%m-%d %H:%M')"
git pull --rebase
git push origin main