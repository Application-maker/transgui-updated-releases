#!/bin/bash
now=$(date +%F)

# Check the arguments
if [ ! "$1" = --no-clone ] && [ ! "$1" = -nc ] && [ ! "$1" = --no-update ] && [ ! "$1" = -nu ]; then
  # Remove old reposirory files
  if [ -d "./transgui" ]; then
    rm -rf ./transgui
  fi

  # Clone the repository
  git clone https://github.com/transmission-remote-gui/transgui.git
fi

# Build the application
cd ./transgui/setup/unix || exit
./build.sh

cd ../../

# Aknowledge version number
VERSION=$(cat VERSION.txt)

# Release the build
gh release create "$VERSION" -t "$now" --repo Max-Gouliaev/transgui-updated-releases -n "" ./Release/*