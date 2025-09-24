#!/usr/bin/env bash
cd $(dirname "$0")

EXTRAOPTS='--db=/usr/local/repocache.db -oAPT::FTPArchive::AlwaysStat=true'
FTPARCHIVE='apt-ftparchive'

for dist in big_sur; do
	for arch in darwin-arm64 darwin-amd64; do
		echo $dist $arch
		binary=binary-${arch}
		contents=Contents-${arch}
		mkdir -p dists/${dist}
		rm -f dists/${dist}/{Release{,.gpg},InRelease}

		cp -a RepoIcon*.png dists/${dist}

		for comp in main testing; do
			if [ ! -d pool/${comp}/${dist} ]; then
				continue;
			fi
			mkdir -p dists/${dist}/${comp}/${binary}
			rm -rf dists/${dist}/${comp}/${binary}/{Packages{,.xz,.zst},Release{,.gpg}}

			$FTPARCHIVE $EXTRAOPTS --arch ${arch} packages pool/${comp}/${dist} > \
				dists/${dist}/${comp}/${binary}/Packages 2>/dev/null
			xz -c9 dists/${dist}/${comp}/${binary}/Packages > dists/${dist}/${comp}/${binary}/Packages.xz
			zstd -q -c19 dists/${dist}/${comp}/${binary}/Packages > dists/${dist}/${comp}/${binary}/Packages.zst

			$FTPARCHIVE $EXTRAOPTS contents pool/${comp}/${dist} > \
				dists/${dist}/${comp}/${contents}
			xz -c9 dists/${dist}/${comp}/${contents} > dists/${dist}/${comp}/${contents}.xz
			zstd -q -c19 dists/${dist}/${comp}/${contents} > dists/${dist}/${comp}/${contents}.zst

			$FTPARCHIVE $EXTRAOPTS release -c config/${arch}-basic.conf dists/${dist}/${comp}/${binary} > dists/${dist}/${comp}/${binary}/Release 2>/dev/null
		done

		$FTPARCHIVE $EXTRAOPTS release -c config/${dist}.conf dists/${dist} > dists/${dist}/Release 2>/dev/null

		gpg -abs -u C59F3798A305ADD7E7E6C7256430292CF9551B0E -o dists/${dist}/Release.gpg dists/${dist}/Release
		gpg -abs -u C59F3798A305ADD7E7E6C7256430292CF9551B0E --clearsign -o dists/${dist}/InRelease dists/${dist}/Release
	done
done
