#!/bin/bash
set -e  # halt immediately on command failure

now=$(date +%F)

# Colors
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LBLUE='\033[1;34m'
NONE='\033[0m'

# Check if the packages are installed
if ! which git || ! which make || ! which tar || ! which lazbuild || ! which gh; then
  printf "${LRED}""Packages are not installed!\n""${NONE}"
  
  # Detect package manager
  file=/etc/os-release
    # Debian
    if grep -q 'ID_LIKE=.*debian.*' "$file" || grep -q 'ID_LIKE=.*ubuntu.*' "$file"; then
      printf "${LGREEN}""Detected Debian based system.\n""${NONE}"
      sudo apt-get -y install git make tar lazarus github-cli
    # RPM-based
    elif grep -q 'ID_LIKE=.*centos.*' "$file" || grep -q 'ID_LIKE=.*fedora.*' "$file"; then
      printf "${LGREEN}""Detected rpm based system.\n""${NONE}"
      sudo yum -y install git make tar lazarus github-cli
    # Arch
    elif grep -q 'ID_LIKE=.*arch.*' "$file"; then
      printf "${LGREEN}""Detected Arch based system.\n""${NONE}"
      sudo pacman -S --needed git make tar lazarus github-cli
    # Unknown
    else
      printf "${LRED}""Could not detect the system type.\n"  "${LGREEN}" "Please install these packages: git, make, tar, lazarus, github-cli\n""${NONE}"
      # pause until keypress
      read -n 1 -s -r -p "Press any key when you have installed these packages..."
    fi
fi


# Check the arguments
if [ ! "$1" = --no-clone ] && [ ! "$1" = -nc ] && [ ! "$1" = --no-update ] && [ ! "$1" = -nu ]; then
  # Check if the argument is empty
  if [ ! -z "$1" ]; then
    printf "${LRED}""Invalid argument!\n""${NONE}"
    printf "${LBLUE}""Available arguments:\n""${NONE}"
    printf "${LBLUE}""-nc(--no-clone) - do not clone the repository\n""${NONE}"
    printf "${LBLUE}""-nu(--no-update) - same as above\n""${NONE}"
    exit 1
  fi
  
  # Remove old reposirory files
  if [ -d "./transgui" ]; then
    rm -rf ./transgui
  fi

  # Clone the repository
  git clone https://github.com/transmission-remote-gui/transgui.git
  if [ ! -d "./transgui" ]; then
    printf "${LRED}""Could not clone the repository!\n""${NONE}"
    exit 1
  fi
else
  if [ ! -d "./transgui" ]; then
    printf "${LRED}""Repository is not found!\n""${NONE}"
    printf "${LRED}""The program will stop now!.\n""${NONE}"
    printf "${LRED}""Because how would you expect for it to work without the repository?\n""${NONE}"
    exit 1
  else
    printf "${LGREEN}""Using existing repository.\n""${NONE}"
  fi
fi

# Check the lazarus default folder
if [ ! -d "/usr/lib/lazarus/default" ]; then
  if [ ! -d "/usr/lib/lazarus/" ]; then 
    printf "${LRED}""Lazarus default folder is not found!\n""${NONE}"
    printf "${LRED}""Check if you have installed Lazarus properly!\n""${NONE}"
    exit 1
  else
    sed -i -e 's=/usr/lib/lazarus/default/=/usr/lib/lazarus/=g' ./transgui/setup/unix/build.sh
  fi
fi

# Build the application
cd ./transgui/setup/unix || exit 1
./build.sh

cd ../../

# Aknowledge version number
VERSION=$(cat VERSION.txt)
lastdigit=$(echo "$VERSION" | grep -oE '[^.]+$')
# $Version without $lastdigit
VERSION="${VERSION%${lastdigit}}"

VERSION="$VERSION$((lastdigit+1))"
VERSION=""$VERSION" BETA"

commit_hash=$(git rev-parse HEAD | cut -c1-7)
commit_message=$(git log -1 --pretty=%B)

# Release the build
if ! gh release create "$now" -t "$VERSION" --repo Max-Gouliaev/transgui-updated-releases -n "[$commit_message($commit_hash)](https://github.com/transmission-remote-gui/transgui/commit/$(git rev-parse HEAD))" ./Release/*; then
  printf '%s\n' "${LRED}Failed to create release. Please check your access token and try again." >&2
  exit 1
fi
exit 0