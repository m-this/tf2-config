#!/bin/sh
# Builds dist/budhud.zip and dist/budhud.bat.
#
# BUILD_CHANNEL=release takes budhud and mastercomfig at the pins in
# versions.env and checks the VPKs against mastercomfig.sha256.
# BUILD_CHANNEL=nightly takes budhud master and the latest mastercomfig release.
set -eu

cd "$(dirname "$0")"
. ./versions.env

channel=${BUILD_CHANNEL:-release}
version=${VERSION:-dev}
zip_url=${ZIP_URL:?ZIP_URL must say where budhud.bat downloads budhud.zip from}

case $channel in
release)
	budhud_ref=$BUDHUD_REF
	mastercomfig_version=$MASTERCOMFIG_VERSION
	;;
nightly)
	budhud_ref=master
	mastercomfig_version=$(curl -fsSL --retry 4 --retry-all-errors "https://api.github.com/repos/$MASTERCOMFIG_REPO/releases/latest" |
		sed -n 's/^  "tag_name": "\(.*\)",$/\1/p')
	[ -n "$mastercomfig_version" ] || { echo "no latest mastercomfig release" >&2; exit 1; }
	;;
*)
	echo "BUILD_CHANNEL must be release or nightly, not $channel" >&2
	exit 1
	;;
esac

rm -rf build dist
mkdir -p build/src build/tf/custom build/tf/cfg dist

git init -q build/src/budhud
git -C build/src/budhud fetch -q --depth 1 "https://github.com/$BUDHUD_REPO.git" "$budhud_ref"
budhud_sha=$(git -C build/src/budhud rev-parse FETCH_HEAD)
git -C build/src/budhud archive --prefix=budhud/ FETCH_HEAD | tar -x -C build/tf/custom
rm -rf build/tf/custom/budhud/.github build/tf/custom/budhud/.gitattributes build/tf/custom/budhud/.gitignore

base_url="https://github.com/$MASTERCOMFIG_REPO/releases/download/$mastercomfig_version"
while read -r _ file; do
	curl -fsSL --retry 4 --retry-all-errors -o "build/tf/custom/$file" "$base_url/$file"
done < mastercomfig.sha256
if [ "$channel" = release ]; then
	(cd build/tf/custom && sha256sum -c --quiet ../../../mastercomfig.sha256)
fi

cp -R cfg/overrides build/tf/cfg/
summary="tf2-config $version ($channel), budhud $(echo "$budhud_sha" | cut -c1-7), mastercomfig $mastercomfig_version"
printf 'echo "%s"\n' "$summary" > build/tf/cfg/overrides/tf2-config.cfg

(cd build && zip -qrX ../dist/budhud.zip tf)

sed -e "s|@ZIP_URL@|$zip_url|" -e "s|@SUMMARY@|$summary|" install/budhud.bat |
	sed 's/$/\r/' > dist/budhud.bat

echo "$summary"
