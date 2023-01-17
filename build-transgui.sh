#!/bin/bash
counter=0
now=$(date +%F)

if [ -d "./transgui" ]; then
  rm -rf ./transgui
fi

git clone https://github.com/transmission-remote-gui/transgui.git
cd ./transgui/setup/unix || exit
./build.sh

cd ../../

VERSION=$(cat VERSION.txt)

filenames=("$( ls ./Release )")

for i in "${filenames[@]}" ; do
  filepaths[counter]="./Release/$i"
  counter=$((counter+1))
  echo "$i"
done

gh release create "$VERSION" -t "$now" --repo Max-Gouliaev/transgui-updated-releases -n "" "$filepaths"