#! /bin/sh -

git add .
git commit -m "from update of AD $(date +'%Y-%m-%d %H:%M')"
git pull --rebase
git push origin main
