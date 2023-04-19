#!/usr/bin/env bash
# Downloads and installs the pre-built gdk libraries for use by green_ios
set -e

# ----- Help
help_message() {
  cat <<- _EOF_
  Downloads and install the pre-built GDK libraries

  Usage: $SCRIPT_NAME [-h|--help] [-c|--commit sha256]

  Options:
    -c, --commit Download the provided commit
    -h, --help  Display this help message and exit

_EOF_
  exit 0
}

# ----- Vars
TAGNAME="release_0.0.61"

NAME="gdk-iphone"
NAME_IPHONESIM="gdk-iphone-sim"


TARBALL="${NAME}.tar.gz"
TARBALL_IPHONESIM="${NAME_IPHONESIM}.tar.gz"

SHA256="0914fa502959f6b2fac55c8af6f75245e7eb26f059345d4c91cf75a733b2f1b0"
SHA256_IPHONESIM="467042dfdc90a36375830c8bc9f8d8dc0d29ddbe51320e4a4d460fce85d0c9a6"

URL="https://github.com/Blockstream/gdk/releases/download/${TAGNAME}/${TARBALL}"
URL_IPHONESIM="https://github.com/Blockstream/gdk/releases/download/${TAGNAME}/${TARBALL_IPHONESIM}"

VALIDATE_CHECKSUM=true
COMMIT=false
GCLOUD_URL="https://storage.googleapis.com/green-gdk-builds/gdk-"

# --- Argument handling
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h | --help)
      help_message ;;
    -c | --commit)
      COMMIT=${2}
      shift 2;;
    -s | --simulator)
      SIMULATOR=true
      shift 1;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]:-}" # restore positional parameters

# Pre-requisites
function check_command() {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "$1 not found, exiting."; exit 1; }
}
check_command curl
check_command gzip
check_command shasum

# Clean up any previous install
rm -rf gdk

if [[ $COMMIT != false ]]; then
  URL="${GCLOUD_URL}${COMMIT}/${TARBALL}"
  URL_IPHONESIM="${GCLOUD_URL}${COMMIT}/${TARBALL_IPHONESIM}"
  VALIDATE_CHECKSUM=false
fi

# Fetch, validate and decompress gdk
echo "Downloading from $URL"
curl -sL -o ${TARBALL} "${URL}"
if [[ $VALIDATE_CHECKSUM = true ]]; then
  echo "Validating checksum $SHA256"
  echo "${SHA256}  ${TARBALL}" | shasum -a 256 --check
fi

tar xvf ${TARBALL}
rm ${TARBALL}


# Fetch, validate and decompress gdk
echo "Downloading from $URL_IPHONESIM"
curl -sL -o ${TARBALL_IPHONESIM} "${URL_IPHONESIM}"
if [[ $VALIDATE_CHECKSUM = true ]]; then
  echo "Validating checksum $SHA256_IPHONESIM"
  echo "${SHA256_IPHONESIM}  ${TARBALL_IPHONESIM}" | shasum -a 256 --check
fi

tar xvf ${TARBALL_IPHONESIM}
rm ${TARBALL_IPHONESIM}

mkdir -p gdk/include
mkdir -p gdk/device
mkdir -p gdk/simulator

# GreenAddress.swift
# mv ${NAME}/share/gdk/GreenAddress.swift Sources/GDK/GreenAddress.swift

# static libs
mv ${NAME}/lib/iphoneos/libgreenaddress_full.a gdk/device/libgreenaddress_full.a
mv ${NAME_IPHONESIM}/lib/iphonesimulator/libgreenaddress_full.a gdk/simulator/libgreenaddress_full.a

# Include files
mv ${NAME}/include/gdk/libwally-core/* gdk/include/
rm -fr ${NAME}/include/gdk/libwally-core/
mv ${NAME}/include/gdk/* gdk/include/

# Combine arch if needed
# lipo -create gdk/device/libgreenaddress_full.a gdk/simulator/libgreenaddress_full.a -output gdk/simulator/libgreenaddress_full_fat.a

# Cleanup
rm -fr $NAME
rm -fr $NAME_IPHONESIM

# Remove release_ and keep only the semantic version
TAG=${TAGNAME#*_}

ZIP_NAME="gdk_ios_${TAG}"

echo "Build ${ZIP_NAME}"
./build_xcframework.sh ${ZIP_NAME}
