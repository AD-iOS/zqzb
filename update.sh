#!/bin/bash
cd /var/mobile/zqzb
dpkg-scanpackages -m debs /dev/null > Packages
gzip -c9 Packages > Packages.gz
git add .
git commit -m "Auto-update $(date)"
git push