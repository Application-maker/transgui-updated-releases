#!/bin/bash
now=$(date +%F)

if [ -d "./transgui" ]; then
  rm -rf ./transgui
fi

git clone https://github.com/transmission-remote-gui/transgui.git
cd ./transgui/setup/unix || exit
./build.sh

cd ../../

VERSION=$(cat VERSION.txt)

gh release create "$VERSION" -t "$now" --repo Max-Gouliaev/transgui-updated-releases -n "" ./Release/*