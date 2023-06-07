#!/bin/bash
set -e  # halt immediately on command failure

now=$(date +%F)

# Colors
LRED='\033[1;31m'
LGREEN='\033[1;32m'
LBLUE='\033[1;34m'
NONE='\033[0m'

# Check if the necessary packages are installed
packages=("git" "make" "tar" "github-cli" "lazarus")

# Map package names to their corresponding commands
declare -A package_commands
package_commands["git"]="git"
package_commands["make"]="make"
package_commands["tar"]="tar"
package_commands["github-cli"]="gh"
package_commands["lazarus"]="lazbuild"

missing_packages=()
for pkg in "${packages[@]}"; do
    # check if package is installed and save it to missing_packages list if not
    if ! command -v "${package_commands[$pkg]}" > /dev/null; then
        missing_packages+=("$pkg")
    fi
done

if (( "${#missing_packages[@]}" > 0 )); then 
    if which apt-get > /dev/null 2>&1; then
        # Debian-based package manager
        printf "${LGREEN}""Detected Debian based system. Installing required packages...\n""${NONE}"
        if ! sudo apt-get update && sudo apt-get -y install "${missing_packages[@]}"; then
            printf "${LRED}""Failed to install packages. Please investigate and try again.""${NONE}" >&2
            exit 1
        fi
    elif which yum > /dev/null 2>&1; then
        # Redhat-based package manager
        printf "${LGREEN}""Detected Red Hat based system. Installing required packages...\n""${NONE}"
        if ! sudo yum -y install "${missing_packages[@]}"; then
            printf "${LRED}""Failed to install packages. Please investigate and try again.""${NONE}" >&2
            exit 1
        fi
    elif which pacman > /dev/null 2>&1; then
        # Arch Linux package manager
        printf "${LGREEN}""Detected Arch Linux based system. Installing required packages...\n""${NONE}"
        if ! sudo pacman -S --needed "${missing_packages[@]}"; then
            printf "${LRED}""Failed to install packages. Please investigate and try again.""${NONE}" >&2
            exit 1
        fi
    else
        # Unable to detect a package manager
        printf "${LRED}""Could not detect package manager! Please install the following packages on your system: ${missing_packages[*]}""${NONE}" >&2
        exit 1
    fi
fi


# Help function
help() {
  printf "${LBLUE}""Available arguments:\n""${NONE}"
  printf "${LBLUE}""-nc(--no-clone) - do not clone the repository\n""${NONE}"
  printf "${LBLUE}""-nu(--no-update) - same as above\n""${NONE}"
  printf "${LBLUE}""-r(--repository) - repository name (e.g. example/transgui)\n""${NONE}"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -nc|--no-clone) no_clone=true ;;
    -nu|--no-update) no_update=true ;;
    -r|--repository) repository="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; help; exit 1 ;;
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
      # Create symbolic link to the actual folder
      sudo ln -s /usr/lib/lazarus /usr/lib/lazarus/default
    fi
fi

# Build the application
cd ./transgui/setup/unix || exit 1
if ! ./build.sh; then
    printf "${LRED}""Build failed!\n""${NONE}"
    exit 1
fi
# Remove the symbolic link to the Lazarus default folder
sudo rm /usr/lib/lazarus/default

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