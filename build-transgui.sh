#!/bin/bash
now=$(date +%F)

# Colors
LRED='\033[1;31m'
LGREEN='\033[1;32m'


# Check if the packages are installed
if [ ! -x "$(command -v git)" ] || [ ! -x "$(command -v make)" ] || [ ! -x "$(command -v tar)" ] || [ ! -x "$(command -v lazbuild)" ] || [ ! -x "$(command -v gh)" ]; then
  printf "%s""$LRED""Packages are not installed!\n"
  
  # Detect package manager
  file=/etc/os-release
    # Debian
    if grep -q 'ID_LIKE=.*debian.*' "$file" || grep -q 'ID_LIKE=.*ubuntu.*' "$file"; then
      printf "%s""$LGREEN""Detected Debian based system.\n"
      apt-get -y install git make tar lazarus github-cli
    # RPM-based
    elif grep -q 'ID_LIKE=.*centos.*' "$file" || grep -q 'ID_LIKE=.*fedora.*' "$file"; then
      printf "%s""$LGREEN""Detected rpm based system.\n"
      yum -y install git make tar lazarus github-cli
    # Arch
    elif grep -q 'ID_LIKE=.*arch.*' "$file"; then
      printf "%s""$LGREEN""Detected Arch based system.\n"
      sudo pacman -S --needed git make tar lazarus github-cli
    # Unknown
    else
      printf "%s""$LRED""Could not detect the system type.\n" "%s" "$LGREEN" "Please install these packages: git, make, tar, lazarus, github-cli\n"
      # pause until keypress
      read -n 1 -s -r -p "Press any key when you have installed these packages..."
    fi
fi


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
lastdigit=$(echo "$VERSION" | grep -oE '[^.]+$')
# $Version without $lastdigit
VERSION=$(echo $VERSION | sed "s/$lastdigit//g")

VERSION="$VERSION$((lastdigit+1))"
VERSION=""$VERSION" BETA"

# Release the build
gh release create "$now" -t "$VERSION" --repo Max-Gouliaev/transgui-updated-releases ./Release/*