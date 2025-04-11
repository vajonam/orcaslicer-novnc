#!/bin/bash

TMPDIR="$(mktemp -d)"

# Fetch all releases (both latest stable and pre-releases)
curl -SsL https://api.github.com/repos/SoftFever/OrcaSlicer/releases > $TMPDIR/releases.json

# Get the latest stable or pre-release that contains a matching AppImage
url=$(jq -r '[.[] | select(.assets[].browser_download_url | test("Linux.*_Ubuntu2404_V.*AppImage$"))][0].assets[] | select(.browser_download_url | test("Linux.*_Ubuntu2404_V.*AppImage$")) | .browser_download_url' $TMPDIR/releases.json)
name=$(jq -r '[.[] | select(.assets[].browser_download_url | test("Linux.*_Ubuntu2404_V.*AppImage$"))][0].assets[] | select(.browser_download_url | test("Linux.*_Ubuntu2404_V.*AppImage$")) | .name' $TMPDIR/releases.json)
version=$(jq -r '[.[] | select(.assets[].browser_download_url | test("Linux.*_Ubuntu2404_V.*AppImage$"))][0].tag_name' $TMPDIR/releases.json)

if [ $# -ne 1 ]; then
  echo "Wrong number of params"
  exit 1
else
  request=$1
fi

case $request in

  url)
    echo $url
    ;;

  name)
    echo $name
    ;;

  version)
    echo $version
    ;;

  *)
    echo "Unknown request"
    ;;
esac

rm -rf $TMPDIR
exit 0
