#!/bin/bash

[ "$(whoami)" == "procursus" ] || { echo "run as procursus user" && exit 8; }

ln -s joe /tmp/procursus.lck || exit 9

cd "$(dirname "$0")"

./update_repo.sh
./update_mac_repo.sh

date +%s > lastupdate

rm /tmp/procursus.lck
