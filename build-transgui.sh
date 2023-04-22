#!/bin/bash
now=$(date +%F)

# Update the reposirory
if [ -d "./transgui" ]; then
  rm -rf ./transgui
fi

# Clone the repository
git clone https://github.com/transmission-remote-gui/transgui.git

# Build the application
cd ./transgui/setup/unix || exit
./build.sh

cd ../../

# Aknowledge version number
VERSION=$(cat VERSION.txt)

# Release the build
gh release create "$VERSION" -t "$now" --repo Max-Gouliaev/transgui-updated-releases -n "" ./Release/*