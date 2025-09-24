#!/bin/sh
cp -a /Users/Shared/build_dist/iphoneos-arm64/1700/* pool/main/iphoneos-arm64/1700/
for cfver in 1800 1900 2000; do
	cp -a /Users/Shared/build_dist/appletvos-arm64/${cfver}/* pool/main/appletvos-arm64/${cfver}/
done
for cfver in 1800 1900; do
	cp -a /Users/Shared/build_dist/iphoneos-arm64-rootless/${cfver}/* pool/main/iphoneos-arm64-rootless/${cfver}/
done
cp -a /Users/Shared/build_dist/darwin-{arm64,amd64}/1700/* pool/main/big_sur/
