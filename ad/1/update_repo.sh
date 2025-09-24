#!/usr/bin/env bash
cd $(dirname "$0")

EXTRAOPTS='--db=/usr/local/repocache.db -oAPT::FTPArchive::AlwaysStat=true'
FTPARCHIVE='apt-ftparchive'

# Update ${cfver}.config for new Architectures
#for ogdist in iphoneos-arm64/1700 iphoneos-arm64-rootless/1{8,9}00; do
for ogdist in iphoneos-arm64/1700 iphoneos-arm64-rootless/{18,19,20,30}00 appletvos-arm64/{18..20}00; do
	if [[ "${ogdist}" == "iphoneos-arm64-rootless"* ]]; then
		dist=$(echo "${ogdist}" | cut -f2 -d '/')
		arch=iphoneos-arm64
	elif [[ "${ogdist}" == "appletvos-arm64-rootless"* ]]; then
		dist=$(echo "${ogdist}" | cut -f2 -d '/')
		arch=appletvos-arm64
	elif [[ "${ogdist}" == "iphoneos-arm"* ]]; then
		dist="${ogdist}"
		arch=iphoneos-arm
	elif [[ "${ogdist}" == "watchos-arm"* ]]; then
		dist="${ogdist}"
		arch=watchos-arm
	else
		dist="${ogdist}"
		arch=$(echo "${ogdist}" | cut -f1 -d '/')
	fi
	echo $dist
	binary=binary-${arch}
	contents=Contents-${arch}
	mkdir -p dists/${dist}
	rm -f dists/${dist}/{Release{,.gpg},InRelease}

	cp -a CydiaIcon*.png dists/${dist}

	for comp in main testing; do
		if [ ! -d pool/${comp}/${ogdist} ]; then
			continue;
		fi
		mkdir -p dists/${dist}/${comp}/${binary}
		rm -f dists/${dist}/${comp}/${binary}/{Packages{,.xz,.zst},Release{,.gpg}}

		$FTPARCHIVE $EXTRAOPTS packages pool/${comp}/${ogdist} > \
			dists/${dist}/${comp}/${binary}/Packages 2>/dev/null
		xz -c9 dists/${dist}/${comp}/${binary}/Packages > dists/${dist}/${comp}/${binary}/Packages.xz
		zstd -q -c19 dists/${dist}/${comp}/${binary}/Packages > dists/${dist}/${comp}/${binary}/Packages.zst
		
		$FTPARCHIVE $EXTRAOPTS contents pool/${comp}/${ogdist} > \
			dists/${dist}/${comp}/${contents}
		xz -c9 dists/${dist}/${comp}/${contents} > dists/${dist}/${comp}/${contents}.xz
		zstd -q -c19 dists/${dist}/${comp}/${contents} > dists/${dist}/${comp}/${contents}.zst

		$FTPARCHIVE $EXTRAOPTS release -c config/${arch}-basic.conf dists/${dist}/${comp}/${binary} > dists/${dist}/${comp}/${binary}/Release 2>/dev/null
	done

	$FTPARCHIVE $EXTRAOPTS release -c config/$(echo "${dist}" | cut -f1 -d '/').conf dists/${dist} > dists/${dist}/Release 2>/dev/null

	gpg -abs -u C59F3798A305ADD7E7E6C7256430292CF9551B0E -o dists/${dist}/Release.gpg dists/${dist}/Release
	gpg -abs -u C59F3798A305ADD7E7E6C7256430292CF9551B0E --clearsign -o dists/${dist}/InRelease dists/${dist}/Release
done
