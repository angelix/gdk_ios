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
TAGNAME="release_0.0.58.post2"

NAME="gdk-iphone"
NAME_IPHONESIM="gdk-iphone-sim"


TARBALL="${NAME}.tar.gz"
TARBALL_IPHONESIM="${NAME_IPHONESIM}.tar.gz"

SHA256="2cd72b2a41f773c03272c7bfece00af36fd5a02f6b82940fa8562b31874e20c7"
SHA256_IPHONESIM="b5df5b33f6129b079f69479198378b56c3e894fd79b1f5b0a98af31a84913c30"

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

#if [[ $SIMULATOR == true ]]; then
#    NAME=${NAME_IPHONESIM}
#    SHA256=${SHA256_IPHONESIM}
#    TARBALL="${NAME}.tar.gz"
#    URL="https://github.com/Blockstream/gdk/releases/download/${TAGNAME}/${TARBALL}"
#fi

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
mv ${NAME}/share/gdk/GreenAddress.swift Sources/GDK/GreenAddress.swift

# static libs
mv ${NAME}/lib/iphone/libgreenaddress_full.a gdk/device/libgreenaddress_full.a
mv ${NAME_IPHONESIM}/lib/iphonesim/libgreenaddress_full.a gdk/simulator/libgreenaddress_full.a

# Include files
mv ${NAME}/include/gdk/libwally-core/* gdk/include/
rm -fr ${NAME}/include/gdk/libwally-core/
mv ${NAME}/include/gdk/* gdk/include/

# lipo -create gdk/device/libgreenaddress_full.a gdk/simulator/libgreenaddress_full.a -output gdk/simulator/libgreenaddress_full_fat.a

# Cleanup
rm -fr $NAME
rm -fr $NAME_IPHONESIM

ZIP_NAME="gdk_ios_${TAGNAME}"

echo "Build ${ZIP_NAME}"
./build_xcframework.sh ${ZIP_NAME}
