#!/bin/bash
set -e  # halt immediately on command failure

now=$(date +%F)

# Colors
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LBLUE='\033[1;34m'
NONE='\033[0m'

# Check if the packages are installed
if ! which git > /dev/null || ! which make > /dev/null || ! which tar > /dev/null || ! which lazbuild > /dev/null || ! which gh > /dev/null; then
  printf "${LRED}""Packages are not installed!\n""${NONE}"
  
  # Detect package manager
  os_release=/etc/os-release
    # Debian
    if grep -q 'ID_LIKE=.*debian.*' "$os_release" || grep -q 'ID_LIKE=.*ubuntu.*' "$os_release"; then
      printf "${LGREEN}""Detected Debian based system.\n""${NONE}"
      sudo apt-get -y install git make tar lazarus github-cli
    # RPM-based
    elif grep -q 'ID_LIKE=.*centos.*' "$os_release" || grep -q 'ID_LIKE=.*fedora.*' "$os_release"; then
      printf "${LGREEN}""Detected rpm based system.\n""${NONE}"
      sudo yum -y install git make tar lazarus github-cli
    # Arch
    elif grep -q 'ID_LIKE=.*arch.*' "$os_release"; then
      printf "${LGREEN}""Detected Arch based system.\n""${NONE}"
      sudo pacman -S --needed git make tar lazarus github-cli
    # Unknown
    else
      printf "${LRED}""Could not detect the system type.\n"  "${LGREEN}" "Please install the following packages on your system: git, make, tar, lazarus, github-cli\n""${NONE}"
      # pause until keypress
      read -n 1 -s -r -p "Press any key when you have installed these packages..."
    fi
fi


# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -nc|--no-clone) no_clone=true ;;
    -nu|--no-update) no_update=true ;;
    -r|--repository) repository="$2"; shift ;;
    *) echo "Unknown parameter passed: $1";
    printf "${LBLUE}""Available arguments:\n""${NONE}"
    printf "${LBLUE}""-nc(--no-clone) - do not clone the repository\n""${NONE}"
    printf "${LBLUE}""-nu(--no-update) - same as above\n""${NONE}"
    printf "${LBLUE}""-r(--repository) - repository name (e.g. example/transgui)\n""${NONE}"
    exit 1 ;;
  esac
  shift
done

# Prompt user for repository if not passed as an argument
if [ -z "$repository" ]; then
  read -p "Enter the repository name (e.g. example/transgui): " repository
fi

# Clone or update repository
if [ "$no_clone" = true ] && [ -d "./transgui" ]; then
  printf "${LGREEN}""Skipping cloning repository"
elif [ ! -d "./transgui" ] || [ "$no_update" = true ]; then
  echo "Cloning repository"
  if ! git clone https://github.com/transmission-remote-gui/transgui.git; then
    printf "${LRED}""Could not clone the repository!\n""${NONE}"
  fi
else
  printf "${LGREEN}""Updating repository"
  cd ./transgui && git pull && cd -
fi

# Check if Lazarus default folder exists
if [ ! -d "/usr/lib/lazarus/default" ]; then
  # Check if Lazarus directory exists
  if [ ! -d "/usr/lib/lazarus/" ]; then 
    printf "${LRED}""Lazarus default folder is not found!\n""${NONE}"
    printf "${LRED}""Check if you have installed Lazarus properly and try to reinstall it!\n""${NONE}"
    exit 1
  else
    # Replace the default folder path with the actual path to Lazarus
    sed -i -e 's=/usr/lib/lazarus/default/=/usr/lib/lazarus/=g' ./transgui/setup/unix/build.sh
  fi
fi

# Build the application
cd ./transgui/setup/unix || exit 1
if ! ./build.sh; then
    printf "${LRED}""Build failed!\n""${NONE}"
    exit 1
fi
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
if ! gh release create "$now" -t "$VERSION" --repo "$repository" -n "[$commit_message($commit_hash)](https://github.com/transmission-remote-gui/transgui/commit/$(git rev-parse HEAD))" ./Release/*; then
  printf "${LRED}Failed to create release. Please check your access token and try again." >&2
  exit 1
fi
exit 0