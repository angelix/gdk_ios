#!/usr/bin/env bash
set -e

XC_NAME="GDKBinaries"
XC_FRAMEWORK="${XC_NAME}.xcframework"
XC_ZIP="${1-$XC_NAME}.zip"

rm -rf $XC_FRAMEWORK
rm -rf $XC_ZIP

xcodebuild -create-xcframework \
  -library ./gdk/device/libgreenaddress_full.a \
  -headers ./gdk/include/ \
  -library ./gdk/simulator/libgreenaddress_full.a \
  -headers ./gdk/include/ \
  -output $XC_FRAMEWORK

zip -r ${XC_ZIP} ${XC_FRAMEWORK}
echo "Checksum:"

openssl dgst -sha256 $XC_ZIP
