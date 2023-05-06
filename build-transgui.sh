#!/bin/bash
now=$(date +%F)

# Colors
LRED='\033[1;31m'

# Check the arguments
if [ ! "$1" = --no-clone ] && [ ! "$1" = -nc ] && [ ! "$1" = --no-update ] && [ ! "$1" = -nu ]; then
  # Remove old reposirory files
  if [ -d "./transgui" ]; then
    rm -rf ./transgui
  fi

  # Clone the repository
  git clone https://github.com/transmission-remote-gui/transgui.git
fi

# Check the lazarus default folder
if [ ! -d "/usr/lib/lazarus/default" ]; then
  if [ ! -d "/usr/lib/lazarus/" ]; then 
    printf "%s""$LRED""Lazarus default folder is not found!\n"
    printf "%s""$LRED""Check if you have installed Lazarus properly!\n"
    exit
  else
    sed -i -e 's=/usr/lib/lazarus/default/=/usr/lib/lazarus/=g' ./transgui/setup/unix/build.sh
  fi
fi

# Build the application
cd ./transgui/setup/unix || exit
./build.sh

cd ../../

# Aknowledge version number
VERSION=$(cat VERSION.txt)

# Release the build
gh release create "$VERSION" -t "$now" --repo Max-Gouliaev/transgui-updated-releases -n "" ./Release/*